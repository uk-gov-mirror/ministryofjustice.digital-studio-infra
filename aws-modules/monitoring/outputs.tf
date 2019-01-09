output "ec2_instance_ip" {
  value = "${aws_eip.monitoring_eip.public_ip}"
}

output "ec2_instance_dns" {
  value = "${aws_instance.monitoring_ec2_instance.public_dns}"
}

output "ec2_instance_secret" {
  value = "${aws_iam_access_key.monitoring_iam_access_key.encrypted_secret}"
}