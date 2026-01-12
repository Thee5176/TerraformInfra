// Use modular resources stored in terraform_iac/resources
module "vpc" {
  source = "./resources/vpc"

  project_name     = var.project_name
  environment_name = var.environment_name
}

module "ec2" {
  source = "./resources/ec2"

  project_name     = var.project_name
  environment_name = var.environment_name

  ec2_instance_type    = var.ec2_instance_type
  ec2_public_key       = var.ec2_public_key
  command_service_port = var.command_service_port
  query_service_port   = var.query_service_port

  vpc_id        = module.vpc.vpc_id
  web_subnet_id = module.vpc.web_subnet_id
}

module "acm" {
  source = "./resources/acm"

  project_name     = var.project_name
  environment_name = var.environment_name

  domain_name = var.domain_name
}

module "alb" {
  source = "./resources/alb"

  project_name     = var.project_name
  environment_name = var.environment_name

  domain_name     = var.domain_name
  certificate_arn = module.acm.certificate_arn
  alb_subnet_ids  = module.vpc.alb_subnet_ids

  ec2_instance_id      = module.ec2.ec2_instance_id
  command_service_port = var.command_service_port
  query_service_port   = var.query_service_port

  vpc_id    = module.vpc.vpc_id
  web_sg_id = module.ec2.web_sg_id

  depends_on = [module.acm]
}

# # Route53 A record pointing domain to ALB
# resource "aws_route53_record" "app_domain" {
#   zone_id = module.acm.route53_zone_id
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = module.alb.alb_dns_name
#     zone_id                = module.alb.alb_zone_id
#     evaluate_target_health = true
#   }

#   depends_on = [module.acm, module.alb]
# }

# # Route53 A record for www subdomain
# resource "aws_route53_record" "www_domain" {
#   zone_id = module.acm.route53_zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = module.alb.alb_dns_name
#     zone_id                = module.alb.alb_zone_id
#     evaluate_target_health = true
#   }

#   depends_on = [module.acm, module.alb]
# }