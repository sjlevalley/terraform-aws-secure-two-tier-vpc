variable "vpc_id" {
  description = "VPC where the security groups are created"
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

