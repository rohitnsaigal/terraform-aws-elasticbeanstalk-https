This module is intended to help you establish all the insfrastructure needed in order to host a website on AWS. 

This module will:
    - zip contents of source code 
    - create an S3 bucket and upload zipped source code
    - create a certificate for your website and a validation record for that certificate
    - create Route53 records so that the provided application points to the elastic beanstalk environment

This module assumes you registered your domain through AWS and therefore already have a hosted zone created for that domain. If you do not have a domain yet, [register one through AWS](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)

How to use this module

1.  Create main.tf

    ```terraform

    module "my_elasticbeanstalk_application" {
        source="github.com/rohitnsaigal/terraform-elasticbeanstalk-https"
        app_domain="<your-app-domain>"
        hosted_zone_domain=<your-registered-domain>
        route53_zone_id="<route53-zoneid-for-your-domain>"
        elastic_beanstalk_name="<yourwebappname>"
    }

    output "s3_bucket_for_my_new_website"{
        value=module.my_elasticbeanstalk_application.application
    }
        

    ```
2. Run `terraform apply`

3. Upload index.html along with other website files to S3 bucket. Until you upload an index.html document, if you visit your newly created website you will get a 404