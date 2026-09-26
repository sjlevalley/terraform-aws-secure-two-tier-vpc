variable "vpc_id" {
  description = "VPC where the load balancer and target group are created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the internal load balancer"
  type        = map(string)
}

variable "internal_alb_security_group_id" {
  description = "Security group ID attached to the internal load balancer"
  type        = string
}

variable "app_port" {
  description = "Port used by the application tier"
  type        = number
}

variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to module resources"
  type        = map(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the internet-facing load balancer"
  type        = map(string)
}

variable "public_alb_security_group_id" {
  description = "Security group ID attached to the public load balancer"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener"
  type        = string
}