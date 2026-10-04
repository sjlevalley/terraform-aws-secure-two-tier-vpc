variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.vpc_cidr)) &&
      can(regex("/16$", var.vpc_cidr))
    )
    error_message = "vpc_cidr must be a valid IPv4 /16 CIDR, such as 10.0.0.0/16."
  }
}

variable "availability_zones" {
  description = "Availability Zones used by the network"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two Availability Zones are required."
  }
}

variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to module resources"
  type        = map(string)
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