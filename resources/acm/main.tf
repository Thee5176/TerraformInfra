# SSL Certificates - Using manually imported ACM certificate by domain
resource "tls_private_key" "ssl_key_pair" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "self_signed_cert" {
  private_key_pem = tls_private_key.ssl_key_pair.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "my_ssl_cert" {
  private_key      = tls_private_key.ssl_key_pair.private_key_pem
  certificate_body = tls_self_signed_cert.self_signed_cert.cert_pem
}