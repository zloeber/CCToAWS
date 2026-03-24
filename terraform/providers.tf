provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
      },
      var.default_tags,
    )
  }
}

# WAF for CloudFront must be created in us-east-1 (CLOUDFRONT scope), even when aws_region is elsewhere.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
      },
      var.default_tags,
    )
  }
}
