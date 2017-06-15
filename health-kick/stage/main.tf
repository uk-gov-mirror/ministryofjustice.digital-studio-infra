terraform {
    required_version = ">= 0.9.8"
    backend "s3" {
        bucket = "moj-studio-webops-terraform"
        key = "health-kick-stage.terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}

variable "app-name" {
    type = "string"
    default = "health-kick-stage"
}

resource "aws_elastic_beanstalk_application" "app" {
    name = "${var.app-name}"
    description = "${var.app-name}"
}

resource "aws_elastic_beanstalk_environment" "app-env" {
    name = "${var.app-name}"
    application = "${aws_elastic_beanstalk_application.app.name}"
    solution_stack_name = "${var.elastic-beanstalk-single-docker}"
    tier = "WebServer"

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "InstanceType"
        value = "t2.micro"
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "IamInstanceProfile"
        value = "aws-elasticbeanstalk-ec2-role"
    }
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name = "ServiceRole"
        value = "aws-elasticbeanstalk-service-role"
    }
}


resource "aws_iam_user" "deployer" {
    name = "${var.app-name}-deployer"
}
resource "aws_iam_group_membership" "ci" {
    name = "${aws_iam_user.deployer.name}"
    users = ["${aws_iam_user.deployer.name}"]
    group = "${aws_iam_group.deployers.name}"
}

resource "aws_iam_user_policy" "deployer" {
    name = "${var.app-name}-deployer"
    user = "${aws_iam_user.deployer.name}"
    # Based on https://gist.github.com/magnetikonline/5034bdbb049181a96ac9
    # and https://gist.github.com/jakubholynet/0055cf69b5b2a9554af67a11828209a5
    policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticbeanstalk:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:elasticbeanstalk:*::solutionstack/*",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:application/${aws_elastic_beanstalk_application.app.name}",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:applicationversion/${aws_elastic_beanstalk_application.app.name}/*",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:environment/${aws_elastic_beanstalk_application.app.name}/*",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:template/${aws_elastic_beanstalk_application.app.name}/*"
            ]
        }
    ]
}
JSON
}

resource "aws_iam_access_key" "deployer" {
    user = "${aws_iam_user.deployer.name}"
}
