# ==============================================================================
# Reusable Terraform Module: Resource Group
# Purpose: Provisions an Azure Resource Group with standardized tags and naming.
# ==============================================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 5.0.0"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
