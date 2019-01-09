###### VPC (networking) CONFIGURATION ######
resource "aws_vpc" "monitoring_vpc" {
  cidr_block           = "${local.default_vpc_ip_range}"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "monitoring_public_subnet" {
  vpc_id            = "${aws_vpc.monitoring_vpc.id}"
  cidr_block        = "${local.default_subnet_ip_range}"

  depends_on = ["aws_internet_gateway.monitoring_igw"]
}

resource "aws_network_acl" "monitoring_default_nacl" {
    vpc_id = "${aws_vpc.monitoring_vpc.id}"
}

resoruce "aws_network_acl_rule" "monitoring_nacl_rule_ssh_in" {
    network_acl_id = "${aws_network_acl.monitoring_default_nacl.id}"
    rule_number    = 210
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "${local.allowed_inbound_ip}"
    from_port      = "22"
    to_port        = "22"
}

resoruce "aws_network_acl_rule" "monitoring_default_nacl_grafana_in" {
    network_acl_id = "${aws_network_acl.monitoring_default_nacl.id}"
    rule_number    = 220
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "${local.allowed_inbound_ip}"
    from_port      = "3000"
    to_port        = "3000"
}

resoruce "aws_network_acl_rule" "monitoring_nacl_rule_all_out" {
    network_acl_id = "${aws_network_acl.monitoring_default_nacl.id}"
    rule_number    = 230
    egress         = true
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = "*"
    to_port        = "*"
}

resource "aws_internet_gateway" "monitoring_igw" {
  vpc_id = "${aws_vpc.monitoring_vpc.id}"
}

resource "aws_default_route_table" "default_monitoring_rt" {
  default_route_table_id = "${aws_vpc.monitoring_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.monitoring_igw.id}"
  }
}

resource "aws_route_table_association" "monitoring_rt_assoc" {
  subnet_id      = "${aws_subnet.monitoring_public_subnet.id}"
  route_table_id = "${aws_route_table.default_monitoring_rt.id}"
}

resource "aws_security_group" "monitoring_ec2_sg" {
  name        = "${local.default_environment_name}_monitoring_sg"
  vpc_id      = "${aws_vpc.monitoring_vpc.id}"
}

resource "aws_security_group_rule" "monitoring_sgrule_allow_all_out" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.monitoring_ec2_sg.id}"
}

resource "aws_security_group_rule" "monitoring_sgrule_grafana_in" {
  type            = "ingress"
  from_port       = 3000
  to_port         = 3000
  protocol        = "tcp"
  cidr_blocks     = ["${local.allowed_inbound_ip}"]
  security_group_id = "${aws_security_group.monitoring_ec2_sg.id}"
}

resource "aws_security_group_rule" "monitoring_sgrule_ssh_in" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["${local.allowed_inbound_ip}"]
  security_group_id = "${aws_security_group.monitoring_ec2_sg.id}"
}

###### IAM CONFIGURATION ######

resource "aws_iam_role" "monitoring_iam_role" {
  name = "${local.default_iam_resource_name_root}-role"

  assume_role_policy = <<EOF
  {
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:GetMetricData",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
    }
EOF
}

resource "aws_iam_policy" "monitoring_iam_policy" {
  name = "${local.default_iam_resource_name_root}-policy"
  description = "Default policy for IAM access to CloudWatch"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:GetMetricData",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "monitoring_iam_policy_attachment" {
  role       = "${aws_iam_role.monitoring_iam_role.name}"
  policy_arn = "${aws_iam_policy.monitoring_iam_policy.arn}"
}

resource "aws_iam_instance_profile" "monitoring_iam_instance_profile" {
  name = "${local.default_iam_resource_name_root}-instance-profile"
  role = "${aws_iam_role.monitoring_iam_role.name}"
}
resource "aws_iam_user" "monitoring_iam_user" {
  name = "${local.default_iam_resource_name_root}-user"
  path = "/system/"
}

resource "aws_iam_access_key" "monitoring_iam_access_key" {
  user    = "${aws_iam_user.monitoring_iam_user.name}"
}

###### EC2 CONFIGURATION ######

data "aws_ami" "monitoring_ec2_default_ami" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
      name   = "name"
      values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

data "template_file" "monitoring_ec2_instance_user_data" {
  template = "${file("${path.module}/ec2_instance_user_data.tpl")}"
}

resource "aws_instance" "monitoring_ec2_instance" {
  ami                  = "${data.aws_ami.monitoring_ec2_default_ami.id}"
  instance_type        = "${local.default_ec2_instance_size}"
  ebs_optimized        = true
  iam_instance_profile = "${aws_iam_instance_profile.monitoring_iam_instance_profile.name}"
  key_name             = "${local.default_ec2_instance_key_pair}"
  user_data = "${data.template_file.monitoring_ec2_instance_user_data.rendered}"
}

resource "aws_network_interface" "monitoring_ec2_nic" {
  subnet_id       = "${aws_subnet.public_a.id}"
  private_ips     = ["${local.default_ec2_instance_private_ips}"]
  security_groups = ["${aws_security_group.monitoring_ec2_sg.id}"]

  attachment {
    instance     = "${aws_instance.monitoring_ec2_instance.id}"
    device_index = 1
  }

  depends_on = ["aws_subnet.monitoring_public_subnet"]
}

resource "aws_eip" "monitoring_eip" {
  instance = "${aws_instance.monitoring_ec2_instance.id}"
  vpc      = true
}