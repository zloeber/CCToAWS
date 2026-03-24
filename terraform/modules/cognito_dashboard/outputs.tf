output "user_pool_id" {
  value = aws_cognito_user_pool.dashboard.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.dashboard.arn
}

output "client_id" {
  value = aws_cognito_user_pool_client.dashboard.id
}

output "issuer" {
  value = "https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${aws_cognito_user_pool.dashboard.id}"
}

output "hosted_ui_domain" {
  value = "${aws_cognito_user_pool_domain.dashboard.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
}
