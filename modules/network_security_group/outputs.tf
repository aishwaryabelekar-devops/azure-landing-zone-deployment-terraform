# ==============================================================================
# Outputs: Network Security Group Module
# ==============================================================================

output "id" {
  description = "The ID of the provisioned Network Security Group."
  value       = azurerm_network_security_group.nsg.id
}

output "name" {
  description = "The name of the provisioned Network Security Group."
  value       = azurerm_network_security_group.nsg.name
}

output "resource_group_name" {
  description = "The name of the Resource Group containing the NSG."
  value       = azurerm_network_security_group.nsg.resource_group_name
}
