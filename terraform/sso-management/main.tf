data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  # Escape ${ for IAM policy JSON so Terraform does not interpolate PrincipalTag.
  execute_api_arn = "arn:aws:execute-api:${var.workload_aws_region}:${var.workload_aws_account_id}:${var.http_api_id}/*/*"
}

data "aws_iam_policy_document" "abac_static_s3" {
  statement {
    sid = "ListBucketScoped"
    actions = [
      "s3:ListBucket",
    ]
    resources = [var.static_bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${aws:PrincipalTag/${var.abac_user_tag_key}}/*"]
    }
  }

  statement {
    sid = "ObjectRWScoped"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
    ]
    resources = [
      "${var.static_bucket_arn}/$${aws:PrincipalTag/${var.abac_user_tag_key}}/*",
    ]
  }
}

data "aws_iam_policy_document" "abac_ecr_shared" {
  statement {
    sid = "EcrAuth"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid = "EcrPushPullSharedRepo"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [var.ecr_repository_arn]
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalTag/${var.abac_user_tag_key}"
      values   = ["*"]
    }
  }
}

data "aws_iam_policy_document" "control_plane_invoke" {
  statement {
    sid = "InvokeRegistryApi"
    actions = [
      "execute-api:Invoke",
    ]
    resources = [local.execute_api_arn]
  }
}

data "aws_iam_policy_document" "cct_publisher_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.abac_static_s3.json,
    data.aws_iam_policy_document.abac_ecr_shared.json,
    data.aws_iam_policy_document.control_plane_invoke.json,
  ]
}

resource "aws_ssoadmin_permission_set" "cct_publisher" {
  name             = var.permission_set_name
  description      = var.permission_set_description
  instance_arn     = local.instance_arn
  session_duration = var.session_duration

  # Relay state is optional (e.g. link to console); leave unset for default.
}

resource "aws_ssoadmin_permission_set_inline_policy" "cct_publisher" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.cct_publisher.arn
  inline_policy      = data.aws_iam_policy_document.cct_publisher_combined.json
}

resource "aws_ssoadmin_account_assignment" "workload" {
  count = var.create_account_assignment && var.assignment_principal_id != null && var.assignment_principal_id != "" ? 1 : 0

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.cct_publisher.arn
  principal_id       = var.assignment_principal_id
  principal_type     = var.assignment_principal_type
  target_id          = var.workload_aws_account_id
  target_type        = "AWS_ACCOUNT"
}

check "account_assignment_inputs" {
  assert {
    condition     = !var.create_account_assignment || (var.assignment_principal_id != null && var.assignment_principal_id != "")
    error_message = "create_account_assignment requires assignment_principal_id (Identity Store user or group ID)."
  }
}
