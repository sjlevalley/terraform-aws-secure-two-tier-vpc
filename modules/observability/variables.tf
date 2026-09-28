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