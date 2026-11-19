# ==============================================================================
# Outputs: Key Vault Module
# ==============================================================================

output "id" {
  description = "The ID of the provisioned Azure Key Vault."
  value       = azurerm_key_vault.kv.id
}

output "name" {
  description = "The name of the provisioned Azure Key Vault."
  value       = azurerm_key_vault.kv.name
}

output "vault_uri" {
  description = "The URI of the Key Vault for performing operations on keys and secrets."
  value       = azurerm_key_vault.kv.vault_uri
}
