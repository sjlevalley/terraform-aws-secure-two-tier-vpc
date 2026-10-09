module "network" {
  source = "../../modules/network"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  nat_gateway_mode   = var.nat_gateway_mode
  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id      = module.network.vpc_id
  app_port    = var.app_port
  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

module "vpc_endpoints" {
  count  = var.enable_vpc_endpoints ? 1 : 0
  source = "../../modules/vpc-endpoints"

  name_prefix             = local.name_prefix
  common_tags             = local.common_tags
  vpc_id                  = module.network.vpc_id
  aws_region              = var.aws_region
  private_subnet_ids      = module.network.private_subnet_ids
  private_route_table_ids = module.network.private_route_table_ids

  allowed_security_group_ids = {
    web = module.security_groups.web_security_group_id
    app = module.security_groups.app_security_group_id
  }
}


module "load_balancing" {
  source = "../../modules/load-balancing"

  vpc_id                         = module.network.vpc_id
  private_subnet_ids             = module.network.private_subnet_ids
  internal_alb_security_group_id = module.security_groups.internal_alb_security_group_id
  app_port                       = var.app_port
  name_prefix                    = local.name_prefix
  common_tags                    = local.common_tags

  public_subnet_ids            = module.network.public_subnet_ids
  public_alb_security_group_id = module.security_groups.public_alb_security_group_id
  certificate_arn              = aws_acm_certificate_validation.public.certificate_arn

  alb_access_logs_enabled         = var.enable_alb_access_logs
  alb_access_logs_bucket          = var.enable_alb_access_logs ? aws_s3_bucket.alb_access_logs[0].bucket : null
  public_alb_access_logs_prefix   = "public-alb"
  internal_alb_access_logs_prefix = "internal-alb"
  enable_alb_deletion_protection = var.enable_alb_deletion_protection

  depends_on = [
    aws_s3_bucket_policy.alb_access_logs
  ]
}

module "instance_identity" {
  source = "../../modules/instance-identity"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}


module "compute" {
  source = "../../modules/compute"

  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  web_security_group_id = module.security_groups.web_security_group_id
  app_security_group_id = module.security_groups.app_security_group_id
  instance_type         = var.instance_type
  name_prefix           = local.name_prefix
  common_tags           = local.common_tags

  instance_profile_name = module.instance_identity.instance_profile_name
  internal_alb_dns_name = module.load_balancing.internal_alb_dns_name
  app_port              = var.app_port
  web_target_group_arn  = module.load_balancing.web_target_group_arn
  app_target_group_arn  = module.load_balancing.app_target_group_arn

  log_group_names = module.observability.log_group_names
}