# ==============================================================================
# Outputs: Subnet Module
# ==============================================================================

output "id" {
  description = "The ID of the provisioned Subnet."
  value       = azurerm_subnet.subnet.id
}

output "name" {
  description = "The name of the provisioned Subnet."
  value       = azurerm_subnet.subnet.name
}

output "address_prefixes" {
  description = "The address prefixes assigned to the Subnet."
  value       = azurerm_subnet.subnet.address_prefixes
}
