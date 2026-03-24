variable "name_prefix" {
  type        = string
  description = "Prefix for resource names."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB and ECS tasks."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for the internet-facing ALB (two AZs)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for Fargate tasks (two AZs)."
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN in the same region as the ALB (HTTPS listener)."
}

variable "ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDRs allowed to reach the ALB on ports 80/443."
  default     = ["0.0.0.0/0"]
}

variable "container_image" {
  type        = string
  description = "Container image for the placeholder service (public registry)."
  default     = "public.ecr.aws/docker/library/nginx:alpine"
}

variable "container_port" {
  type        = number
  default     = 80
  description = "Container listen port (target group matches this)."
}

variable "fargate_cpu" {
  type        = number
  default     = 256
  description = "Fargate task CPU units when placeholder service is enabled."
}

variable "fargate_memory" {
  type        = number
  default     = 512
  description = "Fargate task memory (MiB) when placeholder service is enabled."
}

variable "deploy_placeholder_service" {
  type        = bool
  default     = true
  description = "Run a sample nginx task behind the ALB. Set false to provision ALB + TG + cluster only."
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "CloudWatch log retention for ECS tasks."
}
