data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_lambda" {
  name               = "${var.name_prefix}-api-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "api_lambda" {
  name = "${var.name_prefix}-api-ddb"
  role = aws_iam_role.api_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.name_prefix}-api:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem",
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*",
        ]
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "api_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-api"
  retention_in_days = 14
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.name_prefix}-api"
  role             = aws_iam_role.api_lambda.arn
  handler          = "api.dispatch"
  runtime          = "python3.12"
  filename         = var.api_zip_path
  source_code_hash = filebase64sha256(var.api_zip_path)

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.api_lambda]
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.name_prefix}-http"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS", "DELETE"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  count = var.enable_dashboard ? 1 : 0

  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.name_prefix}-cognito-jwt"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = var.cognito_jwt_issuer
  }
}

resource "aws_apigatewayv2_route" "register" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /v1/register"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "list_apps" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /v1/apps"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "get_app" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /v1/apps/{appId}"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "dashboard_list" {
  count = var.enable_dashboard ? 1 : 0

  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /v1/dashboard/apps"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito[0].id
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "dashboard_get" {
  count = var.enable_dashboard ? 1 : 0

  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /v1/dashboard/apps/{appId}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito[0].id
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "dashboard_delete" {
  count = var.enable_dashboard ? 1 : 0

  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "DELETE /v1/dashboard/apps/{appId}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito[0].id
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  # HTTP API invoke ARN pattern required by Lambda resource policy
  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_apigatewayv2_api.http.id}/*/*"
}

resource "aws_iam_role" "reconcile_lambda" {
  name               = "${var.name_prefix}-reconcile-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "reconcile_lambda" {
  name = "${var.name_prefix}-reconcile-logs"
  role = aws_iam_role.reconcile_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.name_prefix}-reconcile:*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "reconcile_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-reconcile"
  retention_in_days = 14
}

resource "aws_lambda_function" "reconcile" {
  function_name    = "${var.name_prefix}-reconcile"
  role             = aws_iam_role.reconcile_lambda.arn
  handler          = "reconcile.handler"
  runtime          = "python3.12"
  filename         = var.reconcile_zip_path
  source_code_hash = filebase64sha256(var.reconcile_zip_path)

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.reconcile_lambda]
}

resource "aws_cloudwatch_event_rule" "ecr_push" {
  name = "${var.name_prefix}-ecr-push"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      "action-type"     = ["PUSH"]
      "repository-name" = [var.ecr_repository_name]
    }
  })
}

resource "aws_cloudwatch_event_rule" "s3_object" {
  name = "${var.name_prefix}-s3-object-created"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.s3_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "ecr_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ecr_push.name
  target_id = "reconcile"
  arn       = aws_lambda_function.reconcile.arn
}

resource "aws_cloudwatch_event_target" "s3_to_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_object.name
  target_id = "reconcile"
  arn       = aws_lambda_function.reconcile.arn
}

resource "aws_lambda_permission" "reconcile_ecr" {
  statement_id  = "AllowEventBridgeECR"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reconcile.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_push.arn
}

resource "aws_lambda_permission" "reconcile_s3" {
  statement_id  = "AllowEventBridgeS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reconcile.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object.arn
}
