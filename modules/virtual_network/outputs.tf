# ==============================================================================
# Outputs: Virtual Network Module
# ==============================================================================

output "id" {
  description = "The ID of the provisioned Virtual Network."
  value       = azurerm_virtual_network.vnet.id
}

output "name" {
  description = "The name of the provisioned Virtual Network."
  value       = azurerm_virtual_network.vnet.name
}

output "address_space" {
  description = "The list of address spaces configured for the Virtual Network."
  value       = azurerm_virtual_network.vnet.address_space
}

output "guid" {
  description = "The GUID of the Virtual Network."
  value       = azurerm_virtual_network.vnet.guid
}
