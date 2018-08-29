

resource "aws_elastic_beanstalk_application" "pdf-gen-app" {
  name        = "licences-pdf-generator"
  description = "licences-pdf-generator"
}

data "aws_acm_certificate" "pdf-gen-cert" {
  domain = "${var.pdf-gen-app-name}.hmpps.dsd.io"
}

resource "aws_security_group" "pdf-gen-elb" {
  name        = "${var.pdf-gen-app-name}-elb"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "ELB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${local.pdf-gen-allowed-list}"
    security_groups = ["${aws_security_group.ec2.id}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${local.pdf-gen-allowed-list}"
    security_groups = ["${aws_security_group.ec2.id}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.pdf-gen-app-name}-elb"), var.pdf-gen-tags)}"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "pdf-gen-ec2" {
  name        = "${var.pdf-gen-app-name}-ec2"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Pdf Generator EBS EC2 instances"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.pdf-gen-elb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.pdf-gen-app-name}-ec2"), var.pdf-gen-tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elastic_beanstalk_environment" "pdf-gen-app-env" {
  name                = "${var.pdf-gen-app-name}"
  application         = "${aws_elastic_beanstalk_application.pdf-gen-app.name}"
  solution_stack_name = "${data.aws_elastic_beanstalk_solution_stack.docker.name}"
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${aws_security_group.pdf-gen-ec2.id}"
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
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "classic"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = "${aws_security_group.pdf-gen-elb.id}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.pdf-gen-elb.id}"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = "${data.aws_acm_certificate.pdf-gen-cert.arn}"
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
    value     = "${local.elb_ssl_policy}"
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

  # Rolling updates
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "${local.instances}"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "${local.instances + (local.instances == local.mininstances ? 1 : 0)}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "${local.mininstances == "0" ? "false" : "true"}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MinInstancesInService"
    value     = "${local.mininstances}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "${local.instances == local.mininstances ? "RollingWithAdditionalBatch" : "Rolling"}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = "1"
  }

  # Begin app-specific config settings
  tags = "${var.pdf-gen-tags}"
}

locals {
  pdf-gen-cname = "${replace(var.pdf-gen-app-name,"-prod","")}"
}

# Allow AWS's ACM to manage the apps FQDN

resource "aws_acm_certificate" "pdf-gen-cert" {
  domain_name       = "${local.pdf-gen-cname}.${local.azure_dns_zone_name}"
  validation_method = "DNS"
  tags              = "${var.pdf-gen-tags}"
}

resource "azurerm_dns_cname_record" "pdf-gen-cname" {
  name                = "${local.pdf-gen-cname}"
  zone_name           = "${local.azure_dns_zone_name}"
  resource_group_name = "${local.azure_dns_zone_rg}"
  ttl                 = "60"
  record              = "${aws_elastic_beanstalk_environment.pdf-gen-app-env.cname}"
}

locals {
  pdf-gen-aws_record_name = "${replace(aws_acm_certificate.pdf-gen-cert.domain_validation_options.0.resource_record_name,local.azure_dns_zone_name,"")}"
}

resource "azurerm_dns_cname_record" "pdf-gen-acm-verify" {
  name                = "${substr(local.pdf-gen-aws_record_name, 0, length(local.pdf-gen-aws_record_name)-2)}"
  zone_name           = "${local.azure_dns_zone_name}"
  resource_group_name = "${local.azure_dns_zone_rg}"
  ttl                 = "300"
  record              = "${aws_acm_certificate.pdf-gen-cert.domain_validation_options.0.resource_record_value}"
}