locals {
  # Default AWS managed rule groups (vendor AWS). Override via var.waf_managed_rule_groups.
  waf_managed_rules_default = [
    {
      name          = "CommonRuleSet"
      priority      = 10
      managed_name  = "AWSManagedRulesCommonRuleSet"
      metric_suffix = "common"
    },
    {
      name          = "KnownBadInputs"
      priority      = 20
      managed_name  = "AWSManagedRulesKnownBadInputsRuleSet"
      metric_suffix = "badinputs"
    },
    {
      name          = "LinuxRuleSet"
      priority      = 30
      managed_name  = "AWSManagedRulesLinuxRuleSet"
      metric_suffix = "linux"
    },
    {
      name          = "IPReputation"
      priority      = 40
      managed_name  = "AWSManagedRulesAmazonIpReputationList"
      metric_suffix = "iprep"
    },
  ]
}

module "waf_cloudfront" {
  count  = local.static_delivery_enabled && var.enable_waf_cloudfront ? 1 : 0
  source = "./modules/waf_publish"

  providers = {
    aws = aws.us_east_1
  }

  name_prefix         = "${var.name_prefix}-${var.environment}-cf"
  scope               = "CLOUDFRONT"
  description         = "WAF for CloudFront (static sites + dashboard)"
  block_mode          = var.waf_block_mode
  managed_rule_groups = length(var.waf_managed_rule_groups) > 0 ? var.waf_managed_rule_groups : local.waf_managed_rules_default
}

module "waf_regional" {
  count  = local.alb_ecs_enabled && var.enable_waf_alb ? 1 : 0
  source = "./modules/waf_publish"

  name_prefix         = "${var.name_prefix}-${var.environment}-alb"
  scope               = "REGIONAL"
  description         = "WAF for ALB (container ingress)"
  block_mode          = var.waf_block_mode
  managed_rule_groups = length(var.waf_managed_rule_groups) > 0 ? var.waf_managed_rule_groups : local.waf_managed_rules_default
}

resource "aws_wafv2_web_acl_association" "alb" {
  count        = local.alb_ecs_enabled && var.enable_waf_alb ? 1 : 0
  resource_arn = module.alb_ecs_publish[0].alb_arn
  web_acl_arn  = module.waf_regional[0].arn
}
