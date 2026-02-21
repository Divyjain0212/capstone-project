# Monitoring Module - CloudWatch & SNS
resource "aws_sns_topic" "alerts" {
  name = "${var.env}-alerts"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.env}-alerts"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { "stat": "Average" }],
            ["AWS/ApplicationELB", "RequestCount", { "stat": "Sum" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", { "stat": "Average" }],
            ["AWS/ApplicationELB", "HealthyHostCount", { "stat": "Average" }],
            ["AWS/EC2", "CPUUtilization", { "stat": "Average" }],
            ["AWS/EC2", "NetworkIn", { "stat": "Sum" }],
            ["AWS/EC2", "NetworkOut", { "stat": "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.id
          title  = "System Health Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { "stat": "Average" }],
            ["AWS/RDS", "DatabaseConnections", { "stat": "Average" }],
            ["AWS/RDS", "ReadLatency", { "stat": "Average" }],
            ["AWS/RDS", "WriteLatency", { "stat": "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.id
          title  = "Database Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.env}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Alert when CPU exceeds ${var.cpu_threshold}%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.env}-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.unhealthy_host_threshold
  alarm_description   = "Alert when unhealthy host count >= ${var.unhealthy_host_threshold}"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name
    TargetGroup  = var.target_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "target_latency_high" {
  alarm_name          = "${var.env}-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.latency_threshold / 1000  # Convert to seconds
  alarm_description   = "Alert when latency exceeds ${var.latency_threshold}ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.env}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Alert when RDS CPU exceeds ${var.cpu_threshold}%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.env}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "150"
  alarm_description   = "Alert when RDS connections exceed 150"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_db_instance_id
  }
}

# Data source for current region
data "aws_region" "current" {}
