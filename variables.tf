variable "env" {
  type = string
}

variable "dynamodb_table" {
  type = string
}

variable "key" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "key_name"{
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "asg_min_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}

variable "asg_desired_capacity" {
  type = number
}

variable "db_instance_class" {
  type = string
}

variable "port" {
  type = string
}
variable "db_allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_multi_az" {
  type = bool
}

variable "db_backup_retention_days" {
  type = number
}

variable "sns_email_endpoint" {
  type = string
}

variable "cpu_threshold" {
  type = number
}

variable "memory_threshold" {
  type = number
}

variable "unhealthy_host_threshold" {
  type = number
}

variable "latency_threshold" {
  type = number
}