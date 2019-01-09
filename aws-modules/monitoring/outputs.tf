output "ec2_instance_ip" {
  value = "${aws_eip.monitoring_eip.public_ip}"
}

output "ec2_instance_dns" {
  value = "${aws_instance.monitoring_ec2_instance.public_dns}"
}
