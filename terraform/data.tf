data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "api_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/.build/api_lambda.zip"

  source {
    content  = file("${path.module}/../src/lambda/api.py")
    filename = "api.py"
  }
}

data "archive_file" "reconcile_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/.build/reconcile_lambda.zip"

  source {
    content  = file("${path.module}/../src/lambda/reconcile.py")
    filename = "reconcile.py"
  }
}
