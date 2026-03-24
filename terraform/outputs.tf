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

output "static_site_url" {
  description = "Base URL for static sites when CloudFront is enabled (https://hostname/)."
  value       = local.static_delivery_enabled ? "https://${var.static_site_hostname}" : null
}

output "static_cloudfront_distribution_id" {
  description = "CloudFront distribution ID for static content, if enabled."
  value       = try(module.cloudfront_static[0].distribution_id, null)
}

output "static_cloudfront_domain_name" {
  description = "CloudFront *.cloudfront.net hostname (use if DNS to custom hostname is not ready)."
  value       = try(module.cloudfront_static[0].distribution_domain_name, null)
}

output "dashboard_url" {
  description = "HTTPS URL for the apps dashboard when enabled (with static_site_hostname)."
  value       = local.dashboard_enabled && var.static_site_hostname != null ? "https://${var.static_site_hostname}/_platform/dashboard/index.html" : null
}

output "cognito_dashboard_hosted_ui_domain" {
  description = "Cognito hosted UI hostname (OAuth/OIDC) when the dashboard is enabled."
  value       = try(module.cognito_dashboard[0].hosted_ui_domain, null)
}

output "cognito_dashboard_client_id" {
  description = "Cognito app client ID for the dashboard SPA (JWT audience)."
  value       = try(module.cognito_dashboard[0].client_id, null)
}
