# ==============================================================================
# Outputs: Resource Group Module
# ==============================================================================

output "id" {
  description = "The ID of the provisioned Azure Resource Group."
  value       = azurerm_resource_group.rg.id
}

output "name" {
  description = "The name of the provisioned Azure Resource Group."
  value       = azurerm_resource_group.rg.name
}

output "location" {
  description = "The Azure region where the Resource Group is located."
  value       = azurerm_resource_group.rg.location
}
