locals {
  name_prefix = "secure-two-tier-staging"

  common_tags = {
    Project     = "secure-two-tier-vpc"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
