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


output "nat_gateway_id" {
  description = "ID of the NAT gateway used by private subnets"
  value       = aws_nat_gateway.main.id
}
