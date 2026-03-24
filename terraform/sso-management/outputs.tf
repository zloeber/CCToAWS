output "permission_set_arn" {
  description = "Assign this permission set to accounts/groups in IAM Identity Center (if not using create_account_assignment)."
  value       = aws_ssoadmin_permission_set.cct_publisher.arn
}

output "identity_center_instance_arn" {
  description = "SSO instance ARN (for troubleshooting)."
  value       = local.instance_arn
}

output "account_assignment_status" {
  description = "Present when create_account_assignment is true."
  value       = try(aws_ssoadmin_account_assignment.workload[0].id, null)
}
