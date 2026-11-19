# ==============================================================================
# Input Variables: Development Environment
# ==============================================================================

variable "environment" {
  description = "Target deployment environment (e.g., dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short identifier for the landing zone workload."
  type        = string
  default     = "alz"
}

variable "location" {
  description = "The Azure region for deploying landing zone resources."
  type        = string
  default     = "eastus"
}

variable "location_short" {
  description = "Shortened abbreviation of the Azure region for naming conventions."
  type        = string
  default     = "eus"
}

variable "owner" {
  description = "Workload owner or technical contact."
  type        = string
  default     = "aishwaryabelekar-devops"
}

variable "cost_center" {
  description = "Accounting cost center code for billing attribution."
  type        = string
  default     = "devops-lab-101"
}

variable "hub_vnet_address_space" {
  description = "CIDR address space for the central Hub Virtual Network."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "hub_shared_subnet_prefix" {
  description = "CIDR address prefix for the Shared Services subnet in the Hub."
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "hub_gateway_subnet_prefix" {
  description = "CIDR address prefix for the GatewaySubnet in the Hub."
  type        = list(string)
  default     = ["10.10.2.0/27"]
}

variable "hub_bastion_subnet_prefix" {
  description = "CIDR address prefix for the AzureBastionSubnet in the Hub."
  type        = list(string)
  default     = ["10.10.3.0/26"]
}

variable "spoke_vnet_address_space" {
  description = "CIDR address space for the Spoke (Application Landing Zone) Virtual Network."
  type        = list(string)
  default     = ["10.11.0.0/16"]
}

variable "spoke_frontend_subnet_prefix" {
  description = "CIDR address prefix for the Frontend subnet in the Spoke."
  type        = list(string)
  default     = ["10.11.1.0/24"]
}

variable "spoke_backend_subnet_prefix" {
  description = "CIDR address prefix for the Backend/Application subnet in the Spoke."
  type        = list(string)
  default     = ["10.11.2.0/24"]
}

variable "spoke_database_subnet_prefix" {
  description = "CIDR address prefix for the Database subnet in the Spoke."
  type        = list(string)
  default     = ["10.11.3.0/24"]
}

variable "key_vault_tenant_id" {
  description = "The Azure Active Directory (Entra ID) tenant ID."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "tags" {
  description = "Custom tags to append to the environment baseline."
  type        = map(string)
  default     = {}
}
