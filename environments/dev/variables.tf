variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
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

