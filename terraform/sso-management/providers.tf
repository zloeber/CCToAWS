# Use credentials for the Organizations **management** account (or delegated IAM Identity Center admin).
# Many teams use a profile that assumes OrganizationAccountAccessRole or SSO into management.

provider "aws" {
  region = var.management_region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "terraform-sso-management"
      },
      var.default_tags,
    )
  }
}
