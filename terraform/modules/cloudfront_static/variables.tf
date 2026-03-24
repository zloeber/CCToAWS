variable "name_prefix" {
  type        = string
  description = "Prefix for CloudFront resource names."
}

variable "bucket_id" {
  type        = string
  description = "S3 bucket name (static sites)."
}

variable "bucket_arn" {
  type        = string
  description = "S3 bucket ARN."
}

variable "bucket_regional_domain_name" {
  type        = string
  description = "S3 regional domain name for the origin (e.g. bucket.s3.us-east-1.amazonaws.com)."
}

variable "aliases" {
  type        = list(string)
  description = "HTTPS hostnames served by this distribution (e.g. [\"apps.example.com\"])."
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in **us-east-1** (required for custom hostnames on CloudFront)."
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class (e.g. PriceClass_100, PriceClass_200, PriceClass_All)."
}

variable "dashboard_path_pattern" {
  type        = string
  default     = ""
  description = "If set (e.g. /_platform/dashboard/*), add a cache behavior for platform dashboard assets."
}

variable "web_acl_arn" {
  type        = string
  nullable    = true
  default     = null
  description = "Optional WAFv2 Web ACL ARN (CLOUDFRONT scope, created in us-east-1)."
}
