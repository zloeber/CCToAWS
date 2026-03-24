# Shared WAFv2 pattern for CLOUDFRONT (must use us-east-1 provider) or REGIONAL (ALB/API).
# Uses AWS managed rule groups — tune via var.block_mode (count vs block).

resource "aws_wafv2_web_acl" "this" {
  name        = substr(replace("${var.name_prefix}-publish", "_", "-"), 0, 128)
  description = var.description
  scope       = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = replace("${var.name_prefix}-waf", "/", "-")
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = var.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority

      # none = use each rule’s default action inside the group (typically block).
      # count = count-only for all rules in the group (observe in logs/metrics without blocking).
      override_action {
        dynamic "none" {
          for_each = var.block_mode ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = var.block_mode ? [] : [1]
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = replace("${var.name_prefix}-${rule.value.metric_suffix}", "/", "-")
        sampled_requests_enabled   = true
      }
    }
  }
}
