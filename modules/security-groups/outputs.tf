output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "internal_alb_security_group_id" {
  description = "ID of the internal application load balancer security group"
  value       = aws_security_group.internal_alb.id
}

output "public_alb_security_group_id" {
  description = "ID of the public application load balancer security group"
  value       = aws_security_group.public_alb.id
}