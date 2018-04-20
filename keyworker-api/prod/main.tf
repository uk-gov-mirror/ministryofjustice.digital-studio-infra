variable "app-name" {
  type    = "string"
  default = "keyworker-api"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Prod"
  }
}

# This resource is managed in multiple places (keyworker api stage)
resource "aws_elastic_beanstalk_application" "app" {
  name        = "keyworker-api"
  description = "keyworker-api"
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

resource "aws_security_group" "elb" {
  name        = "keyworker-api-elb-group"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Keyworker API ELB security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.app-name}-elb"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ec2" {
  name        = "keyworker-api-ec2-group"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Keyworker API EC2 security group"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.app-name}-ec2"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elastic_beanstalk_environment" "app-env" {
  name                = "${var.app-name}"
  application         = "${aws_elastic_beanstalk_application.app.name}"
  solution_stack_name = "${var.elastic-beanstalk-single-docker}"
  tier                = "WebServer"

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = "${aws_security_group.elb.id}"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.elb.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${aws_security_group.ec2.id}"
  }

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
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "USE_API_GATEWAY_AUTH"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_TOKEN"
    value     = "${data.aws_ssm_parameter.api-gateway-token.value}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JWT_PUBLIC_KEY"
    value     = "${data.aws_ssm_parameter.jwt-public-key.value}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ELITE2_API_URI_ROOT"
    value     = "https://gateway.nomis-api.service.justice.gov.uk/elite2api/api"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_PRIVATE_KEY"
    value     = "${data.aws_ssm_parameter.api-gateway-private-key.value}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APP_DB_SERVER"
    value     = "${aws_db_instance.db.address}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APP_DB_NAME"
    value     = "${aws_db_instance.db.name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_USERNAME"
    value     = "${aws_db_instance.db.username}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_PASSWORD"
    value     = "${aws_db_instance.db.password}"
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

# Allow AWS's ACM to manage keyworker-api.service.hmpps.dsd.io
resource "azurerm_dns_cname_record" "acm-verify" {
  name                = "_229381d145cddae46b7ba27679b3cfc0.keyworker-api"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "_fa0d6825a6caff9b1e19726665096e7e.acm-validations.aws."
}
