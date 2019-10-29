resource "aws_vpc" "vpc" {
  cidr_block                       = "192.168.0.0/26"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = false
  assign_generated_ipv6_cidr_block = true
  tags                             = "${merge(var.tags, map("Name", var.app-name))}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = "${merge(var.tags, map("Name", var.app-name))}"
}

resource "aws_subnet" "public-a" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.0/28"
  availability_zone = "${var.aws_az_a}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-public-a"))}"
}

resource "aws_subnet" "public-b" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.16/28"
  availability_zone = "${var.aws_az_b}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-dmz-b"))}"
}

