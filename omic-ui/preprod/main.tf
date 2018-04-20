variable "app-name" {
  type    = "string"
  default = "omic-prepod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "omic-ui"
    Environment = "PreProd"
  }
}

# This resource is managed in multiple places (omic ui stage)
resource "aws_elastic_beanstalk_application" "app" {
  name        = "omic-ui"
  description = "omic-ui"
}

resource "random_id" "session-secret" {
  byte_length = 40
}

resource "azurerm_resource_group" "group" {
  name     = "omic-ui-preprod"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.app-name}"
  location            = "North Europe"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "Web"
}

resource "aws_acm_certificate" "cert" {
  domain_name = "${var.app-name}.service.hmpps.dsd.io"
  validation_method = "DNS"
  tags {
    Environment = "${var.tags["Environment"]}"
  }
}

data "aws_acm_certificate" "cert" {
  domain = "${var.app-name}.service.hmpps.dsd.io"
}

resource "aws_elastic_beanstalk_environment" "app-env" {
  name                = "${var.app-name}"
  application         = "${aws_elastic_beanstalk_application.app.name}"
  solution_stack_name = "${var.elastic-beanstalk-single-docker}"
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = "${data.aws_acm_certificate.cert.arn}"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = "80"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:policies:tlshigh"
    name      = "LoadBalancerPorts"
    value     = "443"
  }

  setting {
    namespace = "aws:elb:policies:tlshigh"
    name      = "SSLReferencePolicy"
    value     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.vpc.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private-a.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public-a.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Fri:10:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "USE_API_GATEWAY_AUTH"
    value     = "yes"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_ENDPOINT_URL"
    value     = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "KEYWORKER_API_URL"
    value     = "https://keyworker-api-preprod.service.hmpps.dsd.io/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NN_ENDPOINT_URL"
    value     = "https://notm-preprod.service.hmpps.dsd.io/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_TOKEN"
    value     = "${data.aws_ssm_parameter.api-gateway-token.value}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_ID"
    value     = "elite2apiclient"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_SECRET"
    value     = "${data.aws_ssm_parameter.api-client-secret.value}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_PRIVATE_KEY"
    value     = "${data.aws_ssm_parameter.api-gateway-private-key.value}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    value     = "${azurerm_application_insights.insights.instrumentation_key}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "HMPPS_COOKIE_NAME"
    value     = "hmpps-session-dev"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "HMPPS_COOKIE_DOMAIN"
    value     = "hmpps.dsd.io"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SESSION_COOKIE_SECRET"
    value     = "${random_id.session-secret.b64}"
  }

  tags = "${var.tags}"
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "${var.app-name}"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "60"
  record              = "${aws_elastic_beanstalk_environment.app-env.cname}"
}

# Allow AWS's ACM to manage omic-preprod.service.hmpps.dsd.io
resource "azurerm_dns_cname_record" "acm-verify" {
  name                = "_afba74c36ea20f990fd81365eee21b7a.omic-prepod"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "_2552505f3b8070428856ec63d66a004e.acm-validations.aws."
}
