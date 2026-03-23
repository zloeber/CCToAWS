output "aws_account_id" {
  description = "Current caller account."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.id
}

output "static_bucket_id" {
  value = module.s3_static.bucket_id
}

output "static_bucket_arn" {
  value = module.s3_static.bucket_arn
}

output "ecr_repository_url" {
  value = module.ecr_shared.repository_url
}

output "ecr_repository_arn" {
  value = module.ecr_shared.repository_arn
}

output "registry_table_name" {
  value = module.dynamodb_registry.table_name
}

output "http_api_endpoint" {
  value = module.control_plane.http_api_endpoint
}

output "http_api_id" {
  value = module.control_plane.http_api_id
}

output "iam_policy_abac_s3_arn" {
  value = aws_iam_policy.abac_static_s3.arn
}

output "iam_policy_abac_ecr_arn" {
  value = aws_iam_policy.abac_ecr_shared.arn
}

output "iam_policy_invoke_api_arn" {
  value = aws_iam_policy.control_plane_invoke.arn
}

output "abac_user_tag_key" {
  value = var.abac_user_tag_key
}
