locals {
  interface_endpoint_services = toset([
    "ssm",
    "ssmmessages",
    "ec2messages",
    "logs",
    "monitoring",
  ])
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Allows private instances to connect to interface VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "https_from_allowed_security_groups" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow HTTPS from workload security group to VPC endpoints"
}

resource "aws_vpc_security_group_egress_rule" "https_out" {
  security_group_id = aws_security_group.endpoints.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow endpoint responses over HTTPS"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(var.private_route_table_ids)

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(var.private_subnet_ids)
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${each.key}-endpoint"
  })
}