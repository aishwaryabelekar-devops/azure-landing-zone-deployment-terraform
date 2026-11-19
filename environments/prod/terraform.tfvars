# ==============================================================================
# Terraform Variables Assignment: Production Environment (prod)
# Safe sample configuration for learning and portfolio review.
# ==============================================================================

environment    = "prod"
project_name   = "alz"
location       = "eastus"
location_short = "eus"
owner          = "aishwaryabelekar-devops"
cost_center    = "prod-ops-800"

# Hub Network Configuration (Platform Landing Zone - Prod)
hub_vnet_address_space    = ["10.30.0.0/16"]
hub_shared_subnet_prefix  = ["10.30.1.0/24"]
hub_gateway_subnet_prefix = ["10.30.2.0/27"]
hub_bastion_subnet_prefix = ["10.30.3.0/26"]

# Spoke Network Configuration (Application Landing Zone - Prod)
spoke_vnet_address_space     = ["10.31.0.0/16"]
spoke_frontend_subnet_prefix = ["10.31.1.0/24"]
spoke_backend_subnet_prefix  = ["10.31.2.0/24"]
spoke_database_subnet_prefix = ["10.31.3.0/24"]

key_vault_tenant_id = "00000000-0000-0000-0000-000000000000"

tags = {
  DeploymentMethod = "Terraform-IaC"
  Portfolio        = "DevOps-Showcase"
  ReviewStatus     = "Portfolio-Ready"
  Criticality      = "Tier-1"
}
