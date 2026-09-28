output "log_group_names" {
  description = "CloudWatch log group names keyed by purpose"
  value = {
    for key, log_group in aws_cloudwatch_log_group.this :
    key => log_group.name
  }
}