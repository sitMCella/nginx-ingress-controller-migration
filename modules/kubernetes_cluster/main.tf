resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "aks-${var.environment}-${var.location_abbreviation}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = "1.34"
  sku_tier            = "Standard"
  support_plan        = "KubernetesOfficial"

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.0.2.0/24"
    dns_service_ip    = "10.0.2.5"
  }

  default_node_pool {
    name                    = "system"
    vm_size                 = "Standard_DS3_v2"
    node_count              = 1
    auto_scaling_enabled    = false
    host_encryption_enabled = false
    node_public_ip_enabled  = false
    max_pods                = 100
    os_disk_size_gb         = 128
    os_disk_type            = "Managed"
    os_sku                  = "Ubuntu"
    vnet_subnet_id          = var.vnet_subnet_id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  private_cluster_enabled           = false
  node_os_upgrade_channel           = "None"
  azure_policy_enabled              = true
  http_application_routing_enabled  = false
  local_account_disabled            = false
  role_based_access_control_enabled = true

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = var.tags

  lifecycle {
    ignore_changes = [microsoft_defender]
  }
}

resource "azurerm_container_registry" "container_registry" {
  name                          = "crapplication${var.location_abbreviation}${var.location}001"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Standard"
  admin_enabled                 = true
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  tags                          = var.tags
}

resource "azurerm_role_assignment" "application_container_registry_role_assignment" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.kubernetes_cluster.kubelet_identity[0].object_id
}
