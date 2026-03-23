data "aws_iam_policy_document" "abac_static_s3" {
  statement {
    sid = "ListBucketScoped"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3_static.bucket_arn,
    ]
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
      "${module.s3_static.bucket_arn}/$${aws:PrincipalTag/${var.abac_user_tag_key}}/*",
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
    resources = [
      module.ecr_shared.repository_arn,
    ]
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
    resources = [
      "arn:aws:execute-api:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${module.control_plane.http_api_id}/*/*",
    ]
  }
}

resource "aws_iam_policy" "abac_static_s3" {
  name_prefix = "${var.name_prefix}-abac-s3-"
  description = "ABAC-scoped static site access for S3 prefix matching PrincipalTag ${var.abac_user_tag_key}"
  policy      = data.aws_iam_policy_document.abac_static_s3.json
}

resource "aws_iam_policy" "abac_ecr_shared" {
  name_prefix = "${var.name_prefix}-abac-ecr-"
  description = "Shared ECR repository push/pull requiring PrincipalTag ${var.abac_user_tag_key}"
  policy      = data.aws_iam_policy_document.abac_ecr_shared.json
}

resource "aws_iam_policy" "control_plane_invoke" {
  name_prefix = "${var.name_prefix}-invoke-api-"
  description = "Invoke HTTP API for registry register/list operations"
  policy      = data.aws_iam_policy_document.control_plane_invoke.json
}
