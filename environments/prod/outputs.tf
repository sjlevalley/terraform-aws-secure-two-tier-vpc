output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal application load balancer"
  value       = module.load_balancing.internal_alb_dns_name
}

output "app_target_group_arn" {
  description = "ARN of the application target group"
  value       = module.load_balancing.app_target_group_arn
}

output "public_alb_dns_name" {
  description = "DNS name of the public application load balancer"
  value       = module.load_balancing.public_alb_dns_name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.observability.dashboard_name
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic used for CloudWatch alarm notifications"
  value       = module.observability.alerts_topic_arn
}

output "alb_access_logs_bucket_name" {
  description = "S3 bucket that stores public and internal ALB access logs"
  value       = var.enable_alb_access_logs ? aws_s3_bucket.alb_access_logs[0].bucket : null
}

output "vpc_endpoint_security_group_id" {
  description = "Security group ID attached to interface VPC endpoints"
  value       = var.enable_vpc_endpoints ? module.vpc_endpoints[0].endpoint_security_group_id : null
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 gateway endpoint"
  value       = var.enable_vpc_endpoints ? module.vpc_endpoints[0].s3_endpoint_id : null
}

output "interface_vpc_endpoint_ids" {
  description = "Interface endpoint IDs keyed by service name"
  value       = var.enable_vpc_endpoints ? module.vpc_endpoints[0].interface_endpoint_ids : {}
}