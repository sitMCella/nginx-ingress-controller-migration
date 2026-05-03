output "virtual_network_id" {
  description = "The Resource ID of the Azure Virtual Network."
  value       = azurerm_virtual_network.virtual_network.id
}

output "subnet_aks_id" {
  description = "The Resource ID of the Azure Kubernetes Service subnet."
  value       = azurerm_subnet.subnet_aks.id
}

output "subnet_agw_id" {
  description = "The Resource ID of the Azure Application Gateway subnet."
  value       = azurerm_subnet.subnet_agw.id
}
