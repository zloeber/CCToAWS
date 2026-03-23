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
