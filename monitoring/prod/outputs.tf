output "ec2_instance_ip" {
  value = "${module.monitoring.ec2_instance_ip}"
}

output "ec2_instance_dns" {
  value = "${module.monitoring.ec2_instance_dns}"
}

output "ec2_instance_secret" {
  value = "${module.monitoring.ec2_instance_secret}"
}