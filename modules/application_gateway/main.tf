resource "azurerm_public_ip" "application_gateway_public_ip" {
  name                = "ip-${var.environment}-${var.type}-${var.location_abbreviation}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = "agw-${var.environment}-${var.type}-${var.location_abbreviation}-001"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "application-gateway-ip-configuration"
    subnet_id = var.vnet_subnet_id
  }

  frontend_port {
    name = "http-frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.application_gateway_public_ip.id
  }

  backend_address_pool {
    name  = "backend-address-pool-web-application"
    fqdns = [var.internal_load_balancer_ip]
  }

  backend_http_settings {
    name                                = "backend-http-settings"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "probe-web-application"
    pick_host_name_from_backend_address = false
    host_name                           = var.host_name
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend-ip-configuration"
    frontend_port_name             = "http-frontend-port"
    protocol                       = "Http"
    host_name                      = var.host_name
    require_sni                    = false
  }

  request_routing_rule {
    name                       = "web-application-route"
    priority                   = 10
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-address-pool-web-application"
    backend_http_settings_name = "backend-http-settings"
  }

  probe {
    name                                      = "probe-web-application"
    host                                      = var.host_name
    interval                                  = 10
    protocol                                  = "Http"
    path                                      = "/"
    timeout                                   = 5
    unhealthy_threshold                       = 5
    pick_host_name_from_backend_http_settings = false
    match {
      status_code = ["200"]
    }
  }

  tags = var.tags
}
