variable "deployment_version" {
  type        = string
  description = "the version of this deployment"
  default     = "v1"
}

variable "source_code" {
  type        = string
  description = "source code file path"
  default     = "source_code"
}

variable "aws_region" {
    type = string
    description = "region you want your resources to reside"
    default = "us-west-2"
}

variable "app_domain" {
  type        = string
  description = "The domain of your app"
}

variable "hosted_zone_domain" {
  type        = string
  description = "your registered domain your app will reside in"
}

variable "route53_zone_id" {
  type        = string
  description = "zone id for the hosted zone you would like to host your website on"
}

variable "application_port" {
  type        = number
  description = "Port application is listening on"
  default     = 80

}
variable "ssh_listener_port" {
  type        = number
  description = "SSH port"
  default     = 22

}

variable "solution_stack_name" {
  type        = string
  description = "solution stack name"
  default     = "64bit Amazon Linux 2 v5.4.6 running Node.js 14"
}

variable "elastic_beanstalk_name"{
    type = string
    description = "Name for your elastic beanstalk application"
    
}

variable "elastic_beanstalk_description"{
    type = string
    description = "Name for your elastic beanstalk application"
    default = "elastic beanstalk created using a rohitnsaigal terraform module"
}

variable "elastic_beanstalk_environment_name"{
    type = string
    description = "Name for your elastic beanstalk application environment"
    default = "development"
    
}