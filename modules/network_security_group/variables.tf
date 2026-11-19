# ==============================================================================
# Input Variables: Network Security Group Module
# ==============================================================================

variable "name" {
  description = "The name of the Network Security Group (e.g., nsg-app-dev-eastus-01)."
  type        = string
}

variable "location" {
  description = "The Azure region where the NSG will be created."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the NSG will reside."
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the Network Security Group."
  type        = map(string)
  default     = {}
}

variable "security_rules" {
  description = "A list of security rules to configure in the NSG."
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string, "*")
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  default = []
}

variable "subnet_id" {
  description = "Optional Subnet ID to associate this NSG with."
  type        = string
  default     = null
}
