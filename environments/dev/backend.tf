# ==============================================================================
# Remote Backend Configuration: Development Environment (Example Only)
# ==============================================================================
# In production and CI/CD pipelines, state is stored centrally in an Azure Blob Storage
# container with state locking via Blob leases.
#
# To enable this remote backend, uncomment the block below and provide your specific
# Azure Storage Account details, or inject them dynamically via:
#   terraform init -backend-config="storage_account_name=<account>" ...
#
# For local offline validation and syntax checks, this block is kept commented out.
# ==============================================================================

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state-dev-eastus"
#     storage_account_name = "sttfstatedeveastus01"
#     container_name       = "tfstate"
#     key                  = "dev.landingzone.terraform.tfstate"
#     use_oidc             = true
#   }
# }
