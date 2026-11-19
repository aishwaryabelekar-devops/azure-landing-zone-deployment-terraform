# ==============================================================================
# Local Values: Development Environment
# ==============================================================================

locals {
  # Standardized prefix adhering to Azure CAF naming convention
  naming_prefix = "${var.project_name}-${var.environment}-${var.location_short}"

  # Merged tags combining baseline organizational tags with environment metadata
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
    }
  )
}
