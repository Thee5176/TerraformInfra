output "ec2_instance_public_ip" {
  description = "EC2 public IP address (from ec2 module)"
  value       = module.ec2.ec2_public_ip
}

output "alb_dns_name" {
  description = "ALB DNS name (from alb module)"
  value       = module.alb.alb_dns_name
}

output "domain_name" {
  description = "Configured domain name"
  value       = var.domain_name
}

# output "route53_name_servers" {
#   description = "Route53 name servers (update your domain registrar with these)"
#   value       = module.acm.route53_zone_name_servers
# }

output "ssl_certificate_arn" {
  description = "SSL Certificate ARN"
  value       = module.acm.certificate_arn
}

output "application_url" {
  description = "Application URL with HTTPS"
  value       = "https://${var.domain_name}"
}