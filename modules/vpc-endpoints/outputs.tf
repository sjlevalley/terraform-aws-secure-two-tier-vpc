output "endpoint_security_group_id" {
  description = "Security group ID attached to interface VPC endpoints"
  value       = aws_security_group.endpoints.id
}

output "s3_endpoint_id" {
  description = "ID of the S3 gateway endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "interface_endpoint_ids" {
  description = "Interface endpoint IDs keyed by service name"
  value       = { for service, endpoint in aws_vpc_endpoint.interface : service => endpoint.id }
}