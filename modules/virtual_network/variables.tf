# ==============================================================================
# Input Variables: Virtual Network Module
# ==============================================================================

variable "vnet_name" {
  description = "The name of the Azure Virtual Network (e.g., vnet-hub-dev-eastus-01)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.vnet_name))
    error_message = "VNet name may only contain letters, numbers, underscores, periods, and hyphens."
  }
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the VNet will be placed."
  type        = string
}

variable "location" {
  description = "The Azure region where the VNet will reside."
  type        = string
  default     = "eastus"
}

variable "address_space" {
  description = "The address space used by the Virtual Network in CIDR format (e.g., [\"10.10.0.0/16\"])."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space prefix must be provided."
  }
}

variable "dns_servers" {
  description = "List of IP addresses of DNS servers (leave empty to use default Azure-provided DNS)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the Virtual Network."
  type        = map(string)
  default     = {}
}
