variable "project_name" {
    description = "catagorize the project provision"
    type        = string
}

variable "environment_name" {
    description = "catagorize environment purpose e.g.develop, production"
    type        = string
}

variable "vpc_id" {
    description = "VPC id where ALB and related resources will be created"
    type        = string
}

variable "alb_subnet_ids" {
    description = "list of subnets where ALB will be created"
    type        = list(string)
}

variable "ec2_instance_id" {
    description = "Instance id of the web server"
    type        = string
}

variable "command_service_port" {
  description = "Port for the Command Service"
  type        = number
}
variable "query_service_port" {
  description = "Port for the Query Service"
  type        = number
}


variable "domain_name" {
    description = "Domain name for the application load balancer"
    type        = string
}

variable "certificate_arn" {
  description = "ARN of ACM certificate to use for HTTPS; empty = create HTTP listener instead"
  type        = string
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "web_sg_id" {
  description = "Security group id of web (EC2) resources allowed to access by ALB"
  type        = string
}