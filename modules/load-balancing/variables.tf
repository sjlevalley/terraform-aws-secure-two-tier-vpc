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

variable "alb_access_logs_enabled" {
  description = "Whether to enable S3 access logs for both load balancers"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket name that receives ALB access logs"
  type        = string
  default     = null
}

variable "public_alb_access_logs_prefix" {
  description = "S3 prefix for public ALB access logs. Must not include AWSLogs."
  type        = string
  default     = null
}

variable "internal_alb_access_logs_prefix" {
  description = "S3 prefix for internal ALB access logs. Must not include AWSLogs."
  type        = string
  default     = null
}
