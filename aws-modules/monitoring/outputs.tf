output "monitoring_dns_urls" {
  value = ["${aws_instance.monitoring_ec2_instance.public_dns}", "${azurerm_dns_a_record.monitoring_dns_a_record.name}.${azurerm_dns_a_record.monitoring_dns_a_record.zone_name}"]
}

output "monitoring_ip" {
  value = "${aws_eip.monitoring_eip.public_ip}"
}