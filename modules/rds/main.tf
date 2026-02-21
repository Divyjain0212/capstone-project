# RDS Module
resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.env}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier            = "${var.env}-mysql-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period        = var.backup_retention_days
  backup_window                  = "03:00-04:00"
  maintenance_window             = "sun:04:00-sun:05:00"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  deletion_protection             = false
  skip_final_snapshot             = true

  tags = {
    Name = "${var.env}-mysql-db"
  }
}

# RDS Parameter Group for performance tuning
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${var.env}-mysql-params"

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${var.env}-mysql-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}
