variable "project_name" {
    description = "catagorize the project provision"
    type        = string
}

variable "environment_name" {
    description = "catagorize environment purpose e.g.develop, production"
    type        = string
}

variable "domain_name" {
    description = "Domain name for Route53"
    type        = string
}
