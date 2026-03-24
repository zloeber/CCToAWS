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

variable "enable_alb_ecs" {
  type        = bool
  default     = false
  description = "Provision VPC (NAT), internet-facing ALB (HTTPS), ECS Fargate cluster, and optional placeholder service for container apps."
}

variable "alb_certificate_arn" {
  type        = string
  nullable    = true
  default     = null
  description = "ACM certificate ARN in **the same region as aws_region** for the ALB HTTPS listener. Required when enable_alb_ecs is true (unlike CloudFront, ALB cannot use us-east-1-only certs in other regions)."
}

variable "alb_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowed to reach the ALB on 80/443."
}

variable "container_publish_vpc_cidr" {
  type        = string
  default     = "10.42.0.0/16"
  description = "VPC CIDR for the container publish stack (two public + two private subnets)."
}

variable "deploy_placeholder_container_service" {
  type        = bool
  default     = true
  description = "Run a sample nginx Fargate service behind the ALB. Set false for ALB + empty target group only."
}

variable "placeholder_container_image" {
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:alpine"
  description = "Image for the placeholder ECS service when deploy_placeholder_container_service is true."
}

variable "enable_waf_cloudfront" {
  type        = bool
  default     = false
  description = "Attach AWS WAFv2 (managed rule groups) to CloudFront. Web ACL is created in us-east-1. Requires CloudFront to be enabled."
}

variable "enable_waf_alb" {
  type        = bool
  default     = false
  description = "Associate AWS WAFv2 with the publish ALB. Requires enable_alb_ecs."
}

variable "waf_block_mode" {
  type        = bool
  default     = true
  description = "If true, managed rule groups use default actions (typically block). If false, count-only for observation in CloudWatch metrics / sampled requests."
}

variable "waf_managed_rule_groups" {
  type = list(object({
    name          = string
    priority      = number
    managed_name  = string
    metric_suffix = string
  }))
  default     = []
  description = "Optional override for WAF managed rule groups (vendor AWS). Empty = Common, KnownBadInputs, Linux, IP reputation."
}

variable "enable_ecr_enhanced_scanning" {
  type        = bool
  default     = false
  description = "Enable ENHANCED ECR image scanning (Amazon Inspector) for the shared repository name pattern. Replaces the account’s ECR registry scanning configuration in this region."
}
