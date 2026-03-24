variable "name_prefix" {
  type        = string
  description = "Prefix for WAF name and metrics (alphanumeric)."
}

variable "scope" {
  type        = string
  description = "CLOUDFRONT (use in us-east-1) or REGIONAL (same region as ALB)."
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "description" {
  type        = string
  description = "Web ACL description."
  default     = "Managed rule groups for published workloads"
}

variable "block_mode" {
  type        = bool
  default     = true
  description = "If true, managed rules use block (via override count empty). If false, count-only for observation (no automatic block)."
}

variable "managed_rule_groups" {
  type = list(object({
    name          = string
    priority      = number
    managed_name  = string
    metric_suffix = string
  }))
  description = "AWS managed rule groups to attach (vendor AWS)."
}
