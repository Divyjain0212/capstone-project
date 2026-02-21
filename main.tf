terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0"
    }
  }

  backend "s3" {
    bucket         = "dev-terraform-state-divy-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "dev-terraform-lock-table"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = "capstone/${var.env}/db"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  env                  = var.env
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_sg_id
}

# Auto Scaling Group Module
module "autoscaling" {
  source = "./modules/autoscaling"

  env                        = var.env
  port                       = var.port
  app_subnet_ids             = module.vpc.public_subnet_ids
  alb_target_group_arn       = module.alb.target_group_arn
  instance_security_group_id = module.security_groups.app_sg_id
  instance_type              = var.instance_type
  min_size                   = var.asg_min_size
  max_size                   = var.asg_max_size
  desired_capacity           = var.asg_desired_capacity
  ami_id                     = data.aws_ami.amazon_linux_2023.id
  key_name                   = var.key_name
  db_name                    = var.db_name
  db_username                = local.db_creds["db_username"]
  db_password                = local.db_creds["db_password"]
  db_host                    = module.rds.db_endpoint
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  db_subnet_ids         = module.vpc.private_subnet_ids
  db_security_group_id  = module.security_groups.db_sg_id
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_name               = var.db_name
  db_username           = local.db_creds["db_username"]
  db_password           = local.db_creds["db_password"]
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  env                      = var.env
  sns_email_endpoint       = var.sns_email_endpoint
  asg_name                 = module.autoscaling.asg_name
  alb_name                 = module.alb.alb_name
  target_group_name        = module.alb.target_group_name
  rds_db_instance_id       = module.rds.db_instance_id
  cpu_threshold            = var.cpu_threshold
  memory_threshold         = var.memory_threshold
  unhealthy_host_threshold = var.unhealthy_host_threshold
  latency_threshold        = var.latency_threshold
}

# Security Groups
module "security_groups" {
  source = "./modules/security_groups"

  env      = var.env
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}