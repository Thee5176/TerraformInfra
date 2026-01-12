output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.backend_alb.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the ALB"
  value       = aws_lb.backend_alb.zone_id
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.backend_alb.arn
}