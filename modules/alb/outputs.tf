output "alb_id" {
  value = aws_lb.main.id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_name" {
  value = aws_lb.main.name
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "target_group_name" {
  value = aws_lb_target_group.app.name
}