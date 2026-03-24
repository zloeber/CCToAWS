variable "management_region" {
  type        = string
  description = "Region where IAM Identity Center is configured (API calls for ssoadmin use this region)."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Tag: project name."
  default     = "cct"
}

variable "environment" {
  type        = string
  description = "Tag: e.g. prod, platform."
  default     = "platform"
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Extra default tags on the permission set."
}

variable "permission_set_name" {
  type        = string
  description = "IAM Identity Center permission set name shown in console."
  default     = "CCToAWS-Publisher"
}

variable "permission_set_description" {
  type        = string
  description = "Description for the permission set."
  default     = "Publish static sites to S3, push to shared ECR, invoke registry HTTP API (ABAC via session tag)."
}

variable "session_duration" {
  type        = string
  description = "Max session duration for the permission set (ISO 8601), e.g. PT8H."
  default     = "PT8H"
}

variable "workload_aws_account_id" {
  type        = string
  description = "AWS account ID where CCToAWS workload Terraform was applied (S3, ECR, API Gateway)."
}

variable "workload_aws_region" {
  type        = string
  description = "Region of the workload (must match execute-api ARN region)."
}

variable "abac_user_tag_key" {
  type        = string
  description = "Session tag key passed to IAM (e.g. user_id). Must match workload terraform.tfvars."
}

variable "static_bucket_arn" {
  type        = string
  description = "S3 bucket ARN from workload output static_bucket_arn."
}

variable "ecr_repository_arn" {
  type        = string
  description = "ECR repository ARN from workload output ecr_repository_arn."
}

variable "http_api_id" {
  type        = string
  description = "API Gateway HTTP API id from workload output http_api_id."
}

variable "create_account_assignment" {
  type        = bool
  description = "If true, assign the permission set to a principal in workload_aws_account_id (requires assignment_* variables)."
  default     = false
}

variable "assignment_principal_id" {
  type        = string
  description = "Identity Center user or group ID (from IAM Identity Center → Users/Groups)."
  default     = null
  nullable    = true
}

variable "assignment_principal_type" {
  type        = string
  description = "USER or GROUP."
  default     = "GROUP"
  validation {
    condition     = contains(["USER", "GROUP"], var.assignment_principal_type)
    error_message = "assignment_principal_type must be USER or GROUP."
  }
}
