variable "name_prefix" {
  description = "Prefix used for endpoint resource names"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to endpoint resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "ID of the VPC where endpoints are created"
  type        = string
}

variable "aws_region" {
  description = "AWS region used to build VPC endpoint service names"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for interface endpoints"
  type        = map(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs for gateway endpoints"
  type        = map(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to interface endpoints over HTTPS"
  type        = set(string)
}