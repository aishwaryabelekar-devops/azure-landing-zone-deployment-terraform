# ==============================================================================
# Input Variables: Key Vault Module
# ==============================================================================

variable "name" {
  description = "The name of the Azure Key Vault. Must be globally unique, 3-24 alphanum/hyphens."
  type        = string

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24 && can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Key Vault name must be between 3 and 24 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "location" {
  description = "The Azure region where the Key Vault will be created."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the Key Vault will reside."
  type        = string
}

variable "tenant_id" {
  description = "The Azure Active Directory (Entra ID) tenant ID used for authenticating requests."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "sku_name" {
  description = "The SKU name of the Key Vault. Options: standard, premium."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained once soft-deleted (between 7 and 90)."
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Specifies whether protection against purge is enabled. Recommended 'true' for production."
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Boolean flag to specify whether Azure Key Vault uses Role-Based Access Control (RBAC) authorization."
  type        = bool
  default     = true
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets."
  type        = bool
  default     = false
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates."
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault."
  type        = bool
  default     = true
}

variable "network_acls_enabled" {
  description = "Whether to configure custom network ACL rules on the Key Vault."
  type        = bool
  default     = false
}

variable "network_acls_bypass" {
  description = "Specifies which traffic can bypass the network rules. Options: AzureServices, None."
  type        = string
  default     = "AzureServices"
}

variable "network_acls_default_action" {
  description = "The default action when no rule matches. Options: Allow, Deny."
  type        = string
  default     = "Deny"
}

variable "network_acls_ip_rules" {
  description = "List of IP addresses or CIDR blocks allowed to access the Key Vault."
  type        = list(string)
  default     = []
}

variable "network_acls_subnet_ids" {
  description = "List of Subnet IDs allowed to access the Key Vault."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the Key Vault."
  type        = map(string)
  default     = {}
}
