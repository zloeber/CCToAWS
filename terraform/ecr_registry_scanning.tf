# Optional Amazon Inspector–powered enhanced scanning for images pushed to ECR.
# One aws_ecr_registry_scanning_configuration per region per account — applying replaces existing rules in that region.

resource "aws_ecr_registry_scanning_configuration" "enhanced" {
  count = var.enable_ecr_enhanced_scanning ? 1 : 0

  scan_type = "ENHANCED"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "${var.ecr_repository_name}*"
      filter_type = "WILDCARD"
    }
  }
}
