resource "aws_iam_instance_profile" "aws-elasticbeanstalk-ec2-role" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
}

resource "aws_iam_role" "aws-elasticbeanstalk-ec2-role" {
  name = "aws-elasticbeanstalk-ec2-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "elb-web-tier" {
  role       = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "elb-multicontainer-docker" {
  role       = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "elb-worker-tier" {
  role       = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_instance_profile" "aws-elasticbeanstalk-service-role" {
  name = "aws-elasticbeanstalk-service-role"
  role = "${aws_iam_role.aws-elasticbeanstalk-service-role.name}"
}

resource "aws_iam_role" "aws-elasticbeanstalk-service-role" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "elb-enhanced-health" {
  role       = "${aws_iam_role.aws-elasticbeanstalk-service-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "elb-service" {
  role       = "${aws_iam_role.aws-elasticbeanstalk-service-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# resource "aws_iam_user" "deployer" {
#     name = "${var.app-name}-deployer"
# }
# resource "aws_iam_group_membership" "ci" {
#     name = "${aws_iam_user.deployer.name}"
#     users = ["${aws_iam_user.deployer.name}"]
#     group = "${aws_iam_group.deployers.name}"
# }
#
# resource "aws_iam_user_policy" "deployer" {
#     name = "${var.app-name}-deployer"
#     user = "${aws_iam_user.deployer.name}"
#     # Based on https://gist.github.com/magnetikonline/5034bdbb049181a96ac9
#     # and https://gist.github.com/jakubholynet/0055cf69b5b2a9554af67a11828209a5
#     policy = <<JSON
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": [
#                 "elasticbeanstalk:*"
#             ],
#             "Effect": "Allow",
#             "Resource": [
#                 "arn:aws:elasticbeanstalk:*::solutionstack/*",
#                 "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:application/${aws_elastic_beanstalk_application.app.name}",
#                 "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:applicationversion/${aws_elastic_beanstalk_application.app.name}/*",
#                 "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:environment/${aws_elastic_beanstalk_application.app.name}/*",
#                 "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:template/${aws_elastic_beanstalk_application.app.name}/*"
#             ]
#         }
#     ]
# }
# JSON
# }
#
# resource "aws_iam_group" "deployers" {
#     name = "${var.app-name}-ElasticbeanstalkDeployers"
# }
#
# resource "aws_iam_group_policy" "deployers" {
#     name = "elasticbeanstalk-deployment"
#     group = "${aws_iam_group.deployers.name}"
#     # Based on https://gist.github.com/magnetikonline/5034bdbb049181a96ac9
#     # and https://gist.github.com/jakubholynet/0055cf69b5b2a9554af67a11828209a5
#     #
#     # all the bits non-specific to this app bits go in
#     policy = <<JSON
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": [
#                 "autoscaling:SuspendProcesses",
#                 "autoscaling:DescribeScalingActivities",
#                 "autoscaling:ResumeProcesses",
#                 "autoscaling:DescribeAutoScalingGroups",
#                 "autoscaling:UpdateAutoScalingGroup",
#                 "autoscaling:DescribeLaunchConfigurations",
#                 "autoscaling:DescribeScheduledActions",
#                 "autoscaling:TerminateInstanceInAutoScalingGroup",
#                 "ec2:*",
#                 "elasticbeanstalk:CreateStorageLocation"
#             ],
#             "Effect": "Allow",
#             "Resource": "*"
#         },
#         {
#             "Action": [
#                 "cloudformation:GetTemplate",
#                 "cloudformation:DescribeStacks",
#                 "cloudformation:CreateStack",
#                 "cloudformation:CancelUpdateStack",
#                 "cloudformation:ListStackResources",
#                 "cloudformation:DescribeStackResource",
#                 "cloudformation:DescribeStackResources",
#                 "cloudformation:DescribeStackEvents",
#                 "cloudformation:DeleteStack",
#                 "cloudformation:UpdateStack"
#             ],
#             "Effect": "Allow",
#             "Resource": [
#                 "arn:aws:cloudformation:${var.aws_region}:${var.aws_account_id}:*"
#             ]
#         },
#         {
#             "Action": [
#                 "elasticloadbalancing:DescribeInstanceHealth",
#                 "elasticloadbalancing:DescribeLoadBalancers",
#                 "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
#                 "elasticloadbalancing:DeregisterInstancesWithLoadBalancer"
#             ],
#             "Effect": "Allow",
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:${var.aws_region}:${var.aws_account_id}:loadbalancer/awseb-*"
#             ]
#         },
#         {
#             "Action": [
#                 "s3:GetObject"
#             ],
#             "Effect": "Allow",
#             "Resource": [
#                 "arn:aws:s3:::elasticbeanstalk-*/*"
#             ]
#         },
#         {
#             "Action": [
#                 "s3:CreateBucket",
#                 "s3:DeleteObject",
#                 "s3:GetBucketPolicy",
#                 "s3:GetObjectAcl",
#                 "s3:ListBucket",
#                 "s3:PutBucketPolicy",
#                 "s3:PutObject",
#                 "s3:PutObjectAcl"
#             ],
#             "Effect": "Allow",
#             "Resource": [
#                 "arn:aws:s3:::elasticbeanstalk-${var.aws_region}-${var.aws_account_id}",
#                 "arn:aws:s3:::elasticbeanstalk-${var.aws_region}-${var.aws_account_id}/*"
#             ]
#         },
#         {
#             "Action": [
#                 "iam:PassRole"
#             ],
#             "Effect": "Allow",
#             "Resource": [
#                 "arn:aws:iam::${var.aws_account_id}:role/aws-elasticbeanstalk-ec2-role"
#             ]
#         }
#     ]
# }
# JSON
# }
#
#
# resource "aws_iam_access_key" "deployer" {
#     user = "${aws_iam_user.deployer.name}"
# }

