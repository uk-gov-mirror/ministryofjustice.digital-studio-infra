resource "aws_db_subnet_group" "db" {
  name       = "${var.app-name}-db"
  subnet_ids = ["${aws_subnet.db-a.id}", "${aws_subnet.db-b.id}"]

  tags = "${merge(map("Name", "${var.app-name}-db"), var.tags)}"
}

resource "aws_security_group" "db" {
  name        = "${var.app-name}-db-sg"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "${var.app-name} DB security group"

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.ec2.id}"]
  }

  tags = "${merge(map("Name", "${var.app-name}-db"), var.tags)}"
}

resource "random_id" "db-password" {
  byte_length = 16
}

resource "aws_db_parameter_group" "db" {
  name   = "${var.app-name}"
  family = "sqlserver-ex-14.0"

  parameter {
    name = "contained database authentication"
    value = "1"
  }

//  parameter {
//    name  = "rds.force_ssl"
//    value = "1"
//  }
}

resource "aws_db_instance" "db" {
  identifier                = "${var.app-name}"
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "sqlserver-ex"
  engine_version            = "14.00.3015.40.v1"
  parameter_group_name      = "${aws_db_parameter_group.db.name}"
  instance_class            = "db.t2.small"
 // name                      = "${replace(var.app-name, "-", "_")}"
  username                  = "licences"
  password                  = "${random_id.db-password.b64}"
  db_subnet_group_name      = "${aws_db_subnet_group.db.name}"
  vpc_security_group_ids    = ["${aws_security_group.db.id}"]
  publicly_accessible       = "true"
  license_model             = "license-included"
  skip_final_snapshot       = "false"
  final_snapshot_identifier = "${var.app-name}-final"
  storage_encrypted         = "false"

  tags = "${var.tags}"
}
