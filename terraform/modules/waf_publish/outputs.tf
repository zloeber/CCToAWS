output "arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "Web ACL ARN (attach to CloudFront or associate with ALB)."
}

output "id" {
  value       = aws_wafv2_web_acl.this.id
  description = "Web ACL ID."
}
