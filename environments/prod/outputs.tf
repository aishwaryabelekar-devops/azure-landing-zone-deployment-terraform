# ==============================================================================
# Outputs: Production Environment (prod)
# ==============================================================================

output "hub_resource_group_name" {
  description = "The name of the Hub platform resource group."
  value       = module.hub_rg.name
}

output "hub_vnet_name" {
  description = "The name of the central Hub Virtual Network."
  value       = module.hub_vnet.name
}

output "hub_vnet_id" {
  description = "The Resource ID of the central Hub Virtual Network."
  value       = module.hub_vnet.id
}

output "spoke_resource_group_name" {
  description = "The name of the Spoke application landing zone resource group."
  value       = module.spoke_rg.name
}

output "spoke_vnet_name" {
  description = "The name of the Spoke Virtual Network."
  value       = module.spoke_vnet.name
}

output "spoke_vnet_id" {
  description = "The Resource ID of the Spoke Virtual Network."
  value       = module.spoke_vnet.id
}

output "subnet_ids" {
  description = "Map of all provisioned subnet IDs across Hub and Spoke networks."
  value = {
    hub_shared     = module.hub_shared_subnet.id
    hub_gateway    = module.hub_gateway_subnet.id
    hub_bastion    = module.hub_bastion_subnet.id
    spoke_frontend = module.spoke_frontend_subnet.id
    spoke_backend  = module.spoke_backend_subnet.id
    spoke_database = module.spoke_database_subnet.id
  }
}

output "key_vault_name" {
  description = "The name of the application Key Vault."
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "The URI endpoint for the application Key Vault."
  value       = module.key_vault.vault_uri
}

output "peering_ids" {
  description = "Resource IDs for the bi-directional VNet peering connections."
  value = {
    hub_to_spoke = azurerm_virtual_network_peering.hub_to_spoke.id
    spoke_to_hub = azurerm_virtual_network_peering.spoke_to_hub.id
  }
}
