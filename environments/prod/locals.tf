locals {
  name_prefix = "secure-two-tier-production"

  common_tags = {
    Project     = "secure-two-tier-vpc"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
