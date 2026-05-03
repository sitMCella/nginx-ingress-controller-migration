locals {
  tags = {
    environment = var.environment
  }
}

resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.workload_name}-${var.environment}-${var.location_abbreviation}-001"
  location = var.location
}

module "virtual_network" {
  source = "./modules/network"

  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  location_abbreviation = var.location_abbreviation
  environment           = var.environment
  tags                  = local.tags
}

module "kubernetes_cluster" {
  source = "./modules/kubernetes_cluster"

  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  location_abbreviation = var.location_abbreviation
  environment           = var.environment
  dns_prefix            = "${var.workload_name}${var.environment}${var.location_abbreviation}"
  vnet_subnet_id        = module.virtual_network.subnet_aks_id
  authorized_ip_ranges  = var.allowed_public_ip_address_ranges
  subscription_id       = var.subscription_id
  tags                  = local.tags
}

module "application" {
  source = "./modules/application"

  container_registry_name         = module.kubernetes_cluster.container_registry_name
  container_registry_login_server = module.kubernetes_cluster.container_registry_login_server
  subscription_id                 = var.subscription_id
}

module "application_gateway_nginx" {
  source = "./modules/application_gateway"

  resource_group_name       = azurerm_resource_group.resource_group.name
  location                  = var.location
  location_abbreviation     = var.location_abbreviation
  environment               = var.environment
  type                      = "nginx"
  vnet_subnet_id            = module.virtual_network.subnet_agw_id
  internal_load_balancer_ip = var.nginx_internal_load_balancer_ip # External IP address of the NGINX Ingress Controller Kubernetes Service
  host_name                 = "app.local"
  tags                      = local.tags
}

module "application_gateway_haproxy" {
  source = "./modules/application_gateway"

  resource_group_name       = azurerm_resource_group.resource_group.name
  location                  = var.location
  location_abbreviation     = var.location_abbreviation
  environment               = var.environment
  type                      = "haproxy"
  vnet_subnet_id            = module.virtual_network.subnet_agw_id
  internal_load_balancer_ip = var.haproxy_internal_load_balancer_ip # External IP address of the HAProxy Ingress Controller Kubernetes Service
  host_name                 = "app.local"
  tags                      = local.tags
}
