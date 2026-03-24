resource "aws_s3_object" "dashboard_config" {
  count  = local.dashboard_enabled ? 1 : 0
  bucket = module.s3_static.bucket_id
  key    = "_platform/dashboard/config.js"
  content = templatefile("${path.module}/templates/dashboard-config.js.tftpl", {
    aws_region               = data.aws_region.current.id
    cognito_user_pool_id     = module.cognito_dashboard[0].user_pool_id
    cognito_client_id        = module.cognito_dashboard[0].client_id
    cognito_hosted_ui_domain = module.cognito_dashboard[0].hosted_ui_domain
    http_api_endpoint        = module.control_plane.http_api_endpoint
    dashboard_redirect_uri   = local.dashboard_callback_urls[0]
  })
  content_type = "application/javascript"
  etag = md5(templatefile("${path.module}/templates/dashboard-config.js.tftpl", {
    aws_region               = data.aws_region.current.id
    cognito_user_pool_id     = module.cognito_dashboard[0].user_pool_id
    cognito_client_id        = module.cognito_dashboard[0].client_id
    cognito_hosted_ui_domain = module.cognito_dashboard[0].hosted_ui_domain
    http_api_endpoint        = module.control_plane.http_api_endpoint
    dashboard_redirect_uri   = local.dashboard_callback_urls[0]
  }))

  depends_on = [
    module.cognito_dashboard,
    module.control_plane,
  ]
}

resource "aws_s3_object" "dashboard_index" {
  count          = local.dashboard_enabled ? 1 : 0
  bucket         = module.s3_static.bucket_id
  key            = "_platform/dashboard/index.html"
  content_base64 = filebase64("${path.module}/../src/dashboard/index.html")
  content_type   = "text/html; charset=utf-8"
  etag           = filemd5("${path.module}/../src/dashboard/index.html")

  depends_on = [aws_s3_object.dashboard_config]
}

resource "aws_s3_object" "dashboard_callback" {
  count          = local.dashboard_enabled ? 1 : 0
  bucket         = module.s3_static.bucket_id
  key            = "_platform/dashboard/callback.html"
  content_base64 = filebase64("${path.module}/../src/dashboard/callback.html")
  content_type   = "text/html; charset=utf-8"
  etag           = filemd5("${path.module}/../src/dashboard/callback.html")

  depends_on = [aws_s3_object.dashboard_config]
}

resource "aws_s3_object" "dashboard_styles" {
  count          = local.dashboard_enabled ? 1 : 0
  bucket         = module.s3_static.bucket_id
  key            = "_platform/dashboard/styles.css"
  content_base64 = filebase64("${path.module}/../src/dashboard/styles.css")
  content_type   = "text/css; charset=utf-8"
  etag           = filemd5("${path.module}/../src/dashboard/styles.css")

  depends_on = [aws_s3_object.dashboard_config]
}

resource "aws_s3_object" "dashboard_app_js" {
  count          = local.dashboard_enabled ? 1 : 0
  bucket         = module.s3_static.bucket_id
  key            = "_platform/dashboard/app.js"
  content_base64 = filebase64("${path.module}/../src/dashboard/app.js")
  content_type   = "text/javascript; charset=utf-8"
  etag           = filemd5("${path.module}/../src/dashboard/app.js")

  depends_on = [aws_s3_object.dashboard_config]
}
