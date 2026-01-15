variable "project_name" {
    description = "catagorize the project provision"
    type        = string
}

variable "environment_name" {
    description = "catagorize environment purpose e.g.develop, production"
    type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instance"
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

variable "vpc_id" {
  description = "VPC id where EC2 and related resources will be created"
  type        = string
}

variable "web_subnet_id" {
  description = "Subnet id for EC2 instance"
  type        = string
}

variable "ec2_public_key" {
  description = "SSH Public Key for EC2 instance access"
  type        = string
}