# ==============================================================================
# Terraform Variables Assignment: Test / Staging Environment (test)
# Safe sample configuration for learning and portfolio review.
# ==============================================================================

environment    = "test"
project_name   = "alz"
location       = "eastus"
location_short = "eus"
owner          = "aishwaryabelekar-devops"
cost_center    = "devops-lab-101"

# Hub Network Configuration (Platform Landing Zone - Test)
hub_vnet_address_space    = ["10.20.0.0/16"]
hub_shared_subnet_prefix  = ["10.20.1.0/24"]
hub_gateway_subnet_prefix = ["10.20.2.0/27"]
hub_bastion_subnet_prefix = ["10.20.3.0/26"]

# Spoke Network Configuration (Application Landing Zone - Test)
spoke_vnet_address_space     = ["10.21.0.0/16"]
spoke_frontend_subnet_prefix = ["10.21.1.0/24"]
spoke_backend_subnet_prefix  = ["10.21.2.0/24"]
spoke_database_subnet_prefix = ["10.21.3.0/24"]

key_vault_tenant_id = "00000000-0000-0000-0000-000000000000"

tags = {
  DeploymentMethod = "Terraform-IaC"
  Portfolio        = "DevOps-Showcase"
  ReviewStatus     = "Portfolio-Ready"
}
