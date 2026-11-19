# ==============================================================================
# Input Variables: Subnet Module
# ==============================================================================

variable "name" {
  description = "The name of the Subnet (e.g., snet-app-dev-eastus-01)."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the parent VNet resides."
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the parent Virtual Network containing this subnet."
  type        = string
}

variable "address_prefixes" {
  description = "The address prefixes for the subnet in CIDR notation (e.g., [\"10.10.1.0/24\"])."
  type        = list(string)

  validation {
    condition     = length(var.address_prefixes) > 0
    error_message = "At least one address prefix must be specified for the subnet."
  }
}

variable "service_endpoints" {
  description = "The list of Service Endpoints to associate with the subnet (e.g., [\"Microsoft.KeyVault\", \"Microsoft.Storage\"])."
  type        = list(string)
  default     = []
}
