output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "asg_arn" {
  value = aws_autoscaling_group.app.arn
}

output "asg_desired_capacity" {
  value = aws_autoscaling_group.app.desired_capacity
}

output "launch_template_id" {
  value = aws_launch_template.app.id
}