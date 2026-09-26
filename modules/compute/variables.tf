variable "public_subnet_ids" {
  description = "Public subnet IDs keyed by instance name"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs keyed by instance name"
  type        = map(string)
}

variable "web_security_group_id" {
  description = "Web security group ID"
  type        = string
}

variable "app_security_group_id" {
  description = "Application security group ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to module resources"
  type        = map(string)
}


variable "root_volume_size" {
  description = "Size of each EC2 root volume in GiB"
  type        = number
  default     = 8

  validation {
    condition = (
      var.root_volume_size >= 8 &&
      floor(var.root_volume_size) == var.root_volume_size
    )
    error_message = "root_volume_size must be a whole number of at least 8 GiB."
  }
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile attached to EC2 instances"
  type        = string
}

variable "internal_alb_dns_name" {
  description = "DNS name used by Nginx to reach the internal application load balancer"
  type        = string
}

variable "app_port" {
  description = "Port exposed by the internal application load balancer"
  type        = number
}

variable "web_target_group_arn" {
  description = "ARN of the web target group attached to the web ASG"
  type        = string
}

variable "app_target_group_arn" {
  description = "ARN of the app target group attached to the app ASG"
  type        = string
}