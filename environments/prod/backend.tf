# ==============================================================================
# Remote Backend Configuration: Production Environment (Example Only)
# ==============================================================================

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state-prod-eastus"
#     storage_account_name = "sttfstateprodeastus01"
#     container_name       = "tfstate"
#     key                  = "prod.landingzone.terraform.tfstate"
#     use_oidc             = true
#   }
# }
