locals {

  /*ELASTICBEANSTALK LOAD BALANCER SETTINGS*/
  application_loadbalancer_settings = [
    {
      namespace = "aws:elb:listener"
      name      = "ListenerProtocol"
      value     = "HTTP"
    },
    {
      namespace = "aws:elb:listener"
      name      = "InstancePort"
      value     = var.application_port
    },
    {
      namespace = "aws:elb:listener"
      name      = "ListenerEnabled"
      value     = "true"
    },
    {
      namespace = "aws:elb:listener:443"
      name      = "ListenerProtocol"
      value     = "HTTPS"
    },
    {
      namespace = "aws:elb:listener:443"
      name      = "InstancePort"
      value     = var.application_port
    },
    {
      namespace = "aws:elb:listener:443"
      name      = "SSLCertificateId"
      value     = aws_acm_certificate.cert.arn
    },
    {
      namespace = "aws:elb:listener:443"
      name      = "ListenerEnabled"
      value     = "true"
    },
    {
      namespace = "aws:elb:listener:${var.ssh_listener_port}"
      name      = "ListenerProtocol"
      value     = "TCP"
    },
    {
      namespace = "aws:elb:listener:${var.ssh_listener_port}"
      name      = "InstancePort"
      value     = "22"
    },
    {
      namespace = "aws:elb:listener:${var.ssh_listener_port}"
      name      = "ListenerEnabled"
      value     = false
    },
    {
      namespace = "aws:elb:policies"
      name      = "ConnectionSettingIdleTimeout"
      value     = "60"
    },
    {
      namespace = "aws:elb:policies"
      name      = "ConnectionDrainingEnabled"
      value     = "true"
    },
    {
      namespace = "aws:elbv2:listener:default"
      name      = "ListenerEnabled"
      value     = "true"
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "ListenerEnabled"
      value     = "true"
      }, {
      namespace = "aws:elbv2:listener:443"
      name      = "Protocol"
      value     = "HTTPS"
      }, {
      namespace = "aws:elbv2:listener:443"
      name      = "SSLCertificateArns"
      value     = aws_acm_certificate.cert.arn
      }, {
      namespace = "aws:elbv2:listener:443"
      name      = "SSLPolicy"
      value     = "ELBSecurityPolicy-2016-08"
    }
  ]

  domain_name = var.app_domain == "" ? var.hosted_zone_domain : "${var.app_domain}.${var.hosted_zone_domain}"


}



# create a zip of your deployment with terraform
data "archive_file" "api_dist_zip" {
  type        = "zip"
  source_dir  = "${path.root}/${var.source_code}"
  output_path = "${path.root}/${var.deployment_version}.zip"
}

/*AWS*/

provider "aws" {
  region = var.aws_region
}



/*CREATE S3 BUCKET*/

resource "aws_s3_bucket" "web_app" {
  bucket = local.domain_name
}

/*UPLOAD SOURCE CODE TO S3 BUCKET*/

resource "aws_s3_bucket_object" "web_app" {
  bucket = aws_s3_bucket.web_app.id
  key    = "beanstalk/${var.deployment_version}.zip"
  source = "${var.deployment_version}.zip"
}



resource "aws_elastic_beanstalk_application" "web_app" {
  name        = var.elastic_beanstalk_name
  description = var.elastic_beanstalk_description
}

resource "aws_elastic_beanstalk_application_version" "web_app" {
  name        =  var.deployment_version
  application = aws_elastic_beanstalk_application.web_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.web_app.id
  key         = aws_s3_bucket_object.web_app.id

}


resource "aws_elastic_beanstalk_environment" "web_app_env" {
  name                = var.elastic_beanstalk_environment_name
  application         = aws_elastic_beanstalk_application.web_app.name
  solution_stack_name = var.solution_stack_name
  version_label       = aws_elastic_beanstalk_application_version.web_app.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  dynamic "setting" {
    for_each = local.application_loadbalancer_settings
    content {
      namespace = setting.value["namespace"]
      name      = setting.value["name"]
      value     = setting.value["value"]
      resource  = ""
    }
  }

}

/*ROUTE 53*/

data "aws_elastic_beanstalk_hosted_zone" "current" {}

# route 53 redirect record 
resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.web_app_env.cname
    zone_id                = data.aws_elastic_beanstalk_hosted_zone.current.id
    evaluate_target_health = false
  }
}

# route 53 redirect record for www. prefix endpoint version of website
resource "aws_route53_record" "redirect-wwww" {
  zone_id = var.route53_zone_id
  name    = "www.${local.domain_name}"
  type    = "A"



  alias {
    name                   = aws_elastic_beanstalk_environment.web_app_env.cname
    zone_id                = data.aws_elastic_beanstalk_hosted_zone.current.id
    evaluate_target_health = false
  }
}



/*Certificate resoruces to serve over HTTPS*/


resource "aws_acm_certificate" "cert" {
  domain_name               = local.domain_name
  subject_alternative_names = ["www.${local.domain_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

