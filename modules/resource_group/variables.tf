# ==============================================================================
# Input Variables: Resource Group Module
# ==============================================================================

variable "name" {
  description = "The name of the Azure Resource Group (e.g., rg-hub-dev-eastus-01)."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters long."
  }
}

variable "location" {
  description = "The Azure region where the Resource Group will be created."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "A mapping of tags to assign to the Resource Group."
  type        = map(string)
  default     = {}
}
