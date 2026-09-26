output "web_asg_name" {
  description = "Name of the web Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Name of the app Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}