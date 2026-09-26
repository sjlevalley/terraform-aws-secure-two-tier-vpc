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