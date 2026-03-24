variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
}

variable "project_name" {
  type        = string
  description = "Short name used in resource naming."
}

variable "environment" {
  type        = string
  description = "Deployment environment label (e.g. dev, prod)."
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Additional default provider tags."
}

variable "abac_user_tag_key" {
  type        = string
  description = "Session tag key mirrored from Entra/Identity Center for ABAC (e.g. user_id)."
}

variable "static_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for static sites."
}

variable "ecr_repository_name" {
  type        = string
  description = "Shared ECR repository name for container images."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for Lambda/API resources."
  default     = "cct"
}

variable "static_site_hostname" {
  type        = string
  nullable    = true
  default     = null
  description = "HTTPS hostname for the shared static CloudFront distribution (e.g. apps.example.com). Leave null to skip CloudFront. If set, you must also set static_site_certificate_arn."
}

variable "static_site_certificate_arn" {
  type        = string
  nullable    = true
  default     = null
  description = "ACM certificate ARN in **us-east-1** for static_site_hostname (CloudFront requires certificates in us-east-1). If set, you must also set static_site_hostname."
}

variable "static_site_price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class when static delivery is enabled."
}

variable "enable_dashboard" {
  type        = bool
  default     = false
  description = "Create Cognito app + JWT routes + upload dashboard SPA to S3. Requires callback/logout URLs (or static_site_hostname for defaults)."
}

variable "dashboard_cognito_domain_prefix" {
  type        = string
  nullable    = true
  default     = null
  description = "Globally unique Cognito hosted UI domain prefix (max 63 chars). Defaults to <name_prefix>-<environment>-dash."
}

variable "dashboard_cognito_callback_urls" {
  type        = list(string)
  default     = []
  description = "OAuth redirect URIs (include .../callback.html). If empty and static_site_hostname is set, defaults to https://<hostname>/_platform/dashboard/callback.html"
}

variable "dashboard_cognito_logout_urls" {
  type        = list(string)
  default     = []
  description = "OAuth sign-out URIs. If empty and static_site_hostname is set, defaults to https://<hostname>/_platform/dashboard/index.html"
}
