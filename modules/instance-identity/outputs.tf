output "instance_profile_name" {
  description = "Name of the IAM instance profile used by EC2 instances"
  value       = aws_iam_instance_profile.instance.name
}

output "instance_role_arn" {
  description = "ARN of the IAM role assumed by EC2 instances"
  value       = aws_iam_role.instance.arn
}