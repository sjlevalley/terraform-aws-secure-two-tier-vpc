variable "name_prefix" {
  description = "Prefix used for observability resources"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to observability resources"
  type        = map(string)
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

variable "public_alb_arn_suffix" {
  description = "ARN suffix for the public ALB CloudWatch metric dimension"
  type        = string
}

variable "internal_alb_arn_suffix" {
  description = "ARN suffix for the internal ALB CloudWatch metric dimension"
  type        = string
}

variable "web_target_group_arn_suffix" {
  description = "ARN suffix for the web target group CloudWatch metric dimension"
  type        = string
}

variable "app_target_group_arn_suffix" {
  description = "ARN suffix for the app target group CloudWatch metric dimension"
  type        = string
}

variable "alarm_email" {
  description = "Optional email address subscribed to CloudWatch alarm notifications"
  type        = string
  default     = null
}