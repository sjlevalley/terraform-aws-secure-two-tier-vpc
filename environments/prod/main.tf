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