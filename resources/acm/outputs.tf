output "certificate_arn" {
  description = "ARN of the private SSL certificate imported into ACM"
  value       = aws_acm_certificate.my_ssl_cert.arn
}

# output "route53_zone_id" {
#   description = "Route53 hosted zone ID"
#   value       = aws_route53_zone.main.zone_id
# }

# output "route53_zone_name_servers" {
#   description = "Route53 hosted zone name servers"
#   value       = aws_route53_zone.main.name_servers
# }

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}