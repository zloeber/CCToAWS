output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CloudFront distribution ID."
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "CloudFront distribution ARN."
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront *.cloudfront.net hostname (fallback if DNS not configured)."
}

output "hosted_zone_id" {
  value       = aws_cloudfront_distribution.this.hosted_zone_id
  description = "Route 53 hosted zone ID for alias records to this distribution."
}
