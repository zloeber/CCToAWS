output "http_api_id" {
  value = aws_apigatewayv2_api.http.id
}

output "http_api_endpoint" {
  value = aws_apigatewayv2_api.http.api_endpoint
}

output "api_lambda_name" {
  value = aws_lambda_function.api.function_name
}

output "reconcile_lambda_name" {
  value = aws_lambda_function.reconcile.function_name
}
