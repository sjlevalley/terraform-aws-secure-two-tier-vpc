variable "name_prefix" {
  description = "Prefix used for IAM resources names"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to module resources"
  type        = map(string)
}