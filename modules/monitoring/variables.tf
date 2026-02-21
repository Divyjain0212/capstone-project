variable "env" {
  description = "Environment name"
  type        = string
}

variable "sns_email_endpoint" {
  description = "Email endpoint for SNS"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
}

variable "target_group_name" {
  description = "Target group name"
  type        = string
}

variable "rds_db_instance_id" {
  description = "RDS instance ID"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU threshold percentage"
  type        = number
}

variable "memory_threshold" {
  description = "Memory threshold percentage"
  type        = number
}

variable "unhealthy_host_threshold" {
  description = "Unhealthy host threshold"
  type        = number
}

variable "latency_threshold" {
  description = "Latency threshold in milliseconds"
  type        = number
}