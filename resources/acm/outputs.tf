output "certificate_arn" {
  description = "ARN of the private SSL certificate imported into ACM"
  value       = aws_acm_certificate.my_ssl_cert.arn
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}