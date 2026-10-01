module "network" {
  source = "../../modules/network"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
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

module "load_balancing" {
  source = "../../modules/load-balancing"

  vpc_id                          = module.network.vpc_id
  private_subnet_ids              = module.network.private_subnet_ids
  internal_alb_security_group_id  = module.security_groups.internal_alb_security_group_id
  app_port                        = var.app_port
  name_prefix                     = local.name_prefix
  common_tags                     = local.common_tags
  public_subnet_ids               = module.network.public_subnet_ids
  public_alb_security_group_id    = module.security_groups.public_alb_security_group_id
  certificate_arn                 = aws_acm_certificate_validation.public.certificate_arn
  alb_access_logs_enabled         = var.enable_alb_access_logs
  alb_access_logs_bucket          = var.enable_alb_access_logs ? aws_s3_bucket.alb_access_logs[0].bucket : null
  public_alb_access_logs_prefix   = "public-alb"
  internal_alb_access_logs_prefix = "internal-alb"

  depends_on = [
    aws_s3_bucket_policy.alb_access_logs
  ]
}

module "observability" {
  source = "../../modules/observability"

  name_prefix                 = local.name_prefix
  common_tags                 = local.common_tags
  public_alb_arn_suffix       = module.load_balancing.public_alb_arn_suffix
  internal_alb_arn_suffix     = module.load_balancing.internal_alb_arn_suffix
  web_target_group_arn_suffix = module.load_balancing.web_target_group_arn_suffix
  app_target_group_arn_suffix = module.load_balancing.app_target_group_arn_suffix
  alarm_email                 = var.alarm_email
  web_asg_name                = module.compute.web_asg_name
  app_asg_name                = module.compute.app_asg_name
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



module "instance_identity" {
  source = "../../modules/instance-identity"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

resource "aws_acm_certificate" "public" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-cert"
  })
}



resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.public.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "public" {
  certificate_arn         = aws_acm_certificate.public.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_route53_record" "app" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.load_balancing.public_alb_dns_name
    zone_id                = module.load_balancing.public_alb_zone_id
    evaluate_target_health = true
  }
}
