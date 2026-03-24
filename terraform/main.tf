module "s3_static" {
  source      = "./modules/s3_static"
  bucket_name = var.static_bucket_name
}

locals {
  static_delivery_enabled = var.static_site_hostname != null && var.static_site_certificate_arn != null

  alb_ecs_enabled = var.enable_alb_ecs && var.alb_certificate_arn != null && var.alb_certificate_arn != ""

  dashboard_callback_urls = length(var.dashboard_cognito_callback_urls) > 0 ? var.dashboard_cognito_callback_urls : (
    var.static_site_hostname != null ? ["https://${var.static_site_hostname}/_platform/dashboard/callback.html"] : []
  )
  dashboard_logout_urls = length(var.dashboard_cognito_logout_urls) > 0 ? var.dashboard_cognito_logout_urls : (
    var.static_site_hostname != null ? ["https://${var.static_site_hostname}/_platform/dashboard/index.html"] : []
  )
  dashboard_enabled = var.enable_dashboard && length(local.dashboard_callback_urls) > 0 && length(local.dashboard_logout_urls) > 0

  cognito_domain_raw = lower(coalesce(var.dashboard_cognito_domain_prefix, "${var.name_prefix}-${var.environment}-dash"))
  # Cognito domain: alphanumeric + hyphen only; max 63 chars.
  cognito_domain_prefix = substr(
    replace(replace(replace(local.cognito_domain_raw, "_", "-"), ".", "-"), " ", "-"),
    0,
    63
  )
}

module "cloudfront_static" {
  count  = local.static_delivery_enabled ? 1 : 0
  source = "./modules/cloudfront_static"

  name_prefix                 = "${var.name_prefix}-${var.environment}"
  bucket_id                   = module.s3_static.bucket_id
  bucket_arn                  = module.s3_static.bucket_arn
  bucket_regional_domain_name = module.s3_static.bucket_regional_domain_name
  aliases                     = [var.static_site_hostname]
  acm_certificate_arn         = var.static_site_certificate_arn
  price_class                 = var.static_site_price_class
  dashboard_path_pattern      = local.dashboard_enabled ? "/_platform/dashboard/*" : ""
  web_acl_arn                 = length(module.waf_cloudfront) > 0 ? module.waf_cloudfront[0].arn : null

  depends_on = [module.s3_static]
}

module "cognito_dashboard" {
  count  = local.dashboard_enabled ? 1 : 0
  source = "./modules/cognito_dashboard"

  name_prefix   = "${var.name_prefix}-${var.environment}"
  domain_prefix = local.cognito_domain_prefix
  callback_urls = local.dashboard_callback_urls
  logout_urls   = local.dashboard_logout_urls
}

module "vpc_app" {
  count  = local.alb_ecs_enabled ? 1 : 0
  source = "./modules/vpc_app"

  name_prefix = "${var.name_prefix}-${var.environment}"
  vpc_cidr    = var.container_publish_vpc_cidr
}

module "alb_ecs_publish" {
  count  = local.alb_ecs_enabled ? 1 : 0
  source = "./modules/alb_ecs_publish"

  name_prefix                = "${var.name_prefix}-${var.environment}"
  vpc_id                     = module.vpc_app[0].vpc_id
  public_subnet_ids          = module.vpc_app[0].public_subnet_ids
  private_subnet_ids         = module.vpc_app[0].private_subnet_ids
  certificate_arn            = var.alb_certificate_arn
  ingress_cidr_blocks        = var.alb_ingress_cidr_blocks
  deploy_placeholder_service = var.deploy_placeholder_container_service
  container_image            = var.placeholder_container_image

  depends_on = [module.vpc_app]
}

module "ecr_shared" {
  source          = "./modules/ecr_shared"
  repository_name = var.ecr_repository_name
}

module "dynamodb_registry" {
  source     = "./modules/dynamodb_registry"
  table_name = "${var.name_prefix}-${var.environment}-registry"
}

module "control_plane" {
  source = "./modules/control_plane"

  name_prefix         = "${var.name_prefix}-${var.environment}"
  api_zip_path        = data.archive_file.api_lambda_zip.output_path
  reconcile_zip_path  = data.archive_file.reconcile_lambda_zip.output_path
  dynamodb_table_name = module.dynamodb_registry.table_name
  dynamodb_table_arn  = module.dynamodb_registry.table_arn
  ecr_repository_name = var.ecr_repository_name
  s3_bucket_name      = module.s3_static.bucket_id
  aws_region          = data.aws_region.current.id
  aws_account_id      = data.aws_caller_identity.current.account_id

  enable_dashboard   = local.dashboard_enabled
  cognito_jwt_issuer = length(module.cognito_dashboard) > 0 ? module.cognito_dashboard[0].issuer : ""
  cognito_client_id  = length(module.cognito_dashboard) > 0 ? module.cognito_dashboard[0].client_id : ""

  depends_on = [
    module.dynamodb_registry,
    module.s3_static,
  ]
}

check "static_site_delivery" {
  assert {
    condition = (
      (var.static_site_hostname == null && var.static_site_certificate_arn == null) ||
      (var.static_site_hostname != null && var.static_site_certificate_arn != null)
    )
    error_message = "Set both static_site_hostname and static_site_certificate_arn, or omit both to skip CloudFront."
  }
}

check "dashboard_callbacks" {
  assert {
    condition     = !var.enable_dashboard || (length(local.dashboard_callback_urls) > 0 && length(local.dashboard_logout_urls) > 0)
    error_message = "When enable_dashboard is true, set dashboard_cognito_callback_urls and dashboard_cognito_logout_urls, or set static_site_hostname so defaults apply."
  }
}

check "alb_ecs_certificate" {
  assert {
    condition     = !var.enable_alb_ecs || (var.alb_certificate_arn != null && var.alb_certificate_arn != "")
    error_message = "When enable_alb_ecs is true, set alb_certificate_arn to an ACM certificate in the same region as aws_region."
  }
}

check "waf_cloudfront_requires_cf" {
  assert {
    condition     = !var.enable_waf_cloudfront || local.static_delivery_enabled
    error_message = "enable_waf_cloudfront requires CloudFront (static_site_hostname + static_site_certificate_arn)."
  }
}

check "waf_alb_requires_alb" {
  assert {
    condition     = !var.enable_waf_alb || local.alb_ecs_enabled
    error_message = "enable_waf_alb requires enable_alb_ecs with a valid alb_certificate_arn."
  }
}
