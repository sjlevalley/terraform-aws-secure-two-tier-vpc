locals {
  name_prefix = "secure-two-tier-dev"

  common_tags = {
    Project     = "secure-two-tier-vpc"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
