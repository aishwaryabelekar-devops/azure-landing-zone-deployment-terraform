# ==============================================================================
# Local Values: Production Environment
# ==============================================================================

locals {
  naming_prefix = "${var.project_name}-${var.environment}-${var.location_short}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = "2026-11-19"
      Repo        = "azure-landing-zone-deployment"
      Owner       = var.owner
      CostCenter  = var.cost_center
      SLA         = "Mission-Critical"
    }
  )
}
