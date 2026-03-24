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

output "container_publish_alb_dns_name" {
  description = "Public ALB DNS name for container runtime_url (HTTPS)."
  value       = try(module.alb_ecs_publish[0].alb_dns_name, null)
}

output "container_publish_https_url" {
  description = "Base URL for traffic through the publish ALB."
  value       = local.alb_ecs_enabled ? "https://${module.alb_ecs_publish[0].alb_dns_name}" : null
}

output "container_publish_ecs_cluster_name" {
  description = "ECS cluster for Fargate services behind the ALB."
  value       = try(module.alb_ecs_publish[0].ecs_cluster_name, null)
}

output "container_publish_target_group_arn" {
  description = "Default ALB target group ARN."
  value       = try(module.alb_ecs_publish[0].target_group_arn, null)
}

output "container_publish_vpc_id" {
  description = "VPC created for the ALB/ECS publish stack."
  value       = try(module.vpc_app[0].vpc_id, null)
}

output "iam_policy_container_publish_arn" {
  description = "IAM policy for registering task definitions and updating ECS services on the publish cluster."
  value       = try(aws_iam_policy.container_publish[0].arn, null)
}

output "waf_cloudfront_web_acl_arn" {
  description = "WAFv2 Web ACL ARN for CloudFront (us-east-1), if enabled."
  value       = try(module.waf_cloudfront[0].arn, null)
}

output "waf_alb_web_acl_arn" {
  description = "WAFv2 Web ACL ARN for the ALB (regional), if enabled."
  value       = try(module.waf_regional[0].arn, null)
}
