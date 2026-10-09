variable "name_prefix" {
  description = "Prefix used for WAF resource names"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to WAF resources"
  type        = map(string)
}

variable "alb_arn" {
  description = "ARN of the public Application Load Balancer to associate with the WAF web ACL"
  type        = string
}

variable "rate_limit" {
  description = "Maximum requests allowed from a single IP in a 5-minute period"
  type        = number
  default     = 2000
}

variable "managed_rules_count_mode" {
  description = "Whether AWS managed rule groups should run in count mode instead of blocking"
  type        = bool
  default     = true
}