output "alb_arn" {
  value       = aws_lb.this.arn
  description = "Application Load Balancer ARN."
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name for runtime_url or Route 53 alias."
}

output "alb_zone_id" {
  value       = aws_lb.this.zone_id
  description = "Route 53 zone ID for alias records to this ALB."
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "Default target group; attach additional ECS services or register targets here."
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "ECS cluster name for aws ecs deploy / update-service."
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "ECS cluster ARN."
}

output "ecs_service_name" {
  value       = try(aws_ecs_service.placeholder[0].name, null)
  description = "Placeholder ECS service name, if deployed."
}

output "task_execution_role_arn" {
  value       = aws_iam_role.ecs_execution.arn
  description = "Task execution role ARN (for custom task definitions)."
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Security group attached to the ALB."
}

output "ecs_tasks_security_group_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "Security group for Fargate tasks (allows traffic from ALB)."
}

output "ecs_log_group_arn" {
  value       = aws_cloudwatch_log_group.ecs.arn
  description = "CloudWatch log group ARN for ECS task logs."
}
