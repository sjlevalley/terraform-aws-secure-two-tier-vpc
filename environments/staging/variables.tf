variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones used by the lab"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type for the lab"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port used by the application tier"
  type        = number
  default     = 8080
}


variable "domain_name" {
  description = "DNS name used for the public application endpoint"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for domain_name"
  type        = string
}

variable "alarm_email" {
  description = "Optional email address for CloudWatch alarm notifications"
  type        = string
  default     = null
}

variable "enable_alb_access_logs" {
  description = "Whether to enable public and internal ALB access logs in encrypted S3 storage"
  type        = bool
  default     = true
}

variable "alb_access_logs_retention_days" {
  description = "Number of days to retain ALB access logs in S3"
  type        = number
  default     = 90

  validation {
    condition     = var.alb_access_logs_retention_days > 0
    error_message = "ALB access log retention must be at least 1 day."
  }
}

variable "nat_gateway_mode" {
  description = "NAT gateway deployment mode. Use single for low cost or per_az for high availability."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either single or per_az."
  }
}
