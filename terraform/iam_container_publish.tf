data "aws_iam_policy_document" "container_publish" {
  count = local.alb_ecs_enabled ? 1 : 0

  statement {
    sid = "EcsClusterAndServices"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:ListServices",
      "ecs:UpdateService",
    ]
    resources = [
      module.alb_ecs_publish[0].ecs_cluster_arn,
      "arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:service/${module.alb_ecs_publish[0].ecs_cluster_name}/*",
    ]
  }

  statement {
    sid = "EcsTaskDefinitions"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassTaskExecutionRole"
    actions   = ["iam:PassRole"]
    resources = [module.alb_ecs_publish[0].task_execution_role_arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid = "EcsLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      module.alb_ecs_publish[0].ecs_log_group_arn,
      "${module.alb_ecs_publish[0].ecs_log_group_arn}:*",
    ]
  }
}

resource "aws_iam_policy" "container_publish" {
  count       = local.alb_ecs_enabled ? 1 : 0
  name_prefix = "${var.name_prefix}-container-publish-"
  description = "Register task definitions and update ECS services in the shared publish cluster (attach to publisher roles)."
  policy      = data.aws_iam_policy_document.container_publish[0].json
}
