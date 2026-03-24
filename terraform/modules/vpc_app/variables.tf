variable "name_prefix" {
  type        = string
  description = "Prefix for resource Name tags."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.42.0.0/16"
  description = "IPv4 CIDR for the VPC (two public + two private /20 subnets derived via cidrsubnet)."
}
