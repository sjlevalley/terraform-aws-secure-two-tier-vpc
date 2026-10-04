output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = { for name, subnet in aws_subnet.public : name => subnet.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = { for name, subnet in aws_subnet.private : name => subnet.id }

  depends_on = [aws_route.private_internet]
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = { for key, nat in aws_nat_gateway.main : key => nat.id }
}

output "private_route_table_ids" {
  description = "IDs of the private route tables keyed by private subnet name"
  value       = { for key, route_table in aws_route_table.private : key => route_table.id }
}
