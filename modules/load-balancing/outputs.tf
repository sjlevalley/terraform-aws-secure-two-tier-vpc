output "internal_alb_dns_name" {
  description = "DNS name of the internal application load balancer"
  value       = aws_lb.internal.dns_name
}

output "app_target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app.arn
}

output "public_alb_dns_name" {
  description = "DNS name of the public application load balancer"
  value       = aws_lb.public.dns_name
}

output "web_target_group_arn" {
  description = "ARN of the web target group"
  value       = aws_lb_target_group.web.arn
}


output "public_alb_zone_id" {
  description = "Hosted zone ID of the public application load balancer"
  value       = aws_lb.public.zone_id
}


output "public_alb_arn_suffix" {
  description = "ARN suffix used for public ALB CloudWatch metrics"
  value       = aws_lb.public.arn_suffix
}

output "internal_alb_arn_suffix" {
  description = "ARN suffix used for internal ALB CloudWatch metrics"
  value       = aws_lb.internal.arn_suffix
}

output "web_target_group_arn_suffix" {
  description = "ARN suffix used for web target group CloudWatch metrics"
  value       = aws_lb_target_group.web.arn_suffix
}

output "app_target_group_arn_suffix" {
  description = "ARN suffix used for app target group CloudWatch metrics"
  value       = aws_lb_target_group.app.arn_suffix
}