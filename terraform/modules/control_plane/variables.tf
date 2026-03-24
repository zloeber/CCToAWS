variable "name_prefix" {
  type = string
}

variable "api_zip_path" {
  type = string
}

variable "reconcile_zip_path" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "enable_dashboard" {
  type        = bool
  description = "Enable Cognito JWT routes for the web dashboard."
  default     = false
}

variable "cognito_jwt_issuer" {
  type        = string
  description = "Cognito issuer URL for API Gateway JWT authorizer."
  default     = ""
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito app client ID (JWT audience)."
  default     = ""
}
