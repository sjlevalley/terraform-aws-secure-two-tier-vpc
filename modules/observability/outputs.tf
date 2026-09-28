output "log_group_names" {
  description = "CloudWatch log group names keyed by purpose"
  value = {
    for key, log_group in aws_cloudwatch_log_group.this :
    key => log_group.name
  }
}


output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}
