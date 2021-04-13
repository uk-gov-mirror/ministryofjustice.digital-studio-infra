resource "azurerm_dns_zone" "service-hmpps" {
  name                = "service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_ns_record" "nomis-api" {
  name                = "nomis-api"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = 300
  records             = ["ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns1-07.azure-dns.com.", "ns4-07.azure-dns.info."]
}

output "service_hmpps_dsd_io_namesevers" {
  value = [azurerm_dns_zone.service-hmpps.name_servers]
}

resource "azurerm_dns_zone" "az_justice_gov_uk" {
  name                = "az.justice.gov.uk"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_zone" "studio-hosting" {
  name                = "studio-hosting.service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_ns_record" "studio-hosting" {
  name                = "studio-hosting"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = 300
  records             = ["ns4-07.azure-dns.info.", "ns3-07.azure-dns.org.", "ns2-07.azure-dns.net.", "ns1-07.azure-dns.com."]
}

resource "azurerm_dns_a_record" "reporting_lsast_nomis" {
  name                = "reporting.lsast-nomis"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["10.40.44.198"]
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_oasys" {
  name                = "bridge-oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_onr" {
  name                = "bridge-onr"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "onr-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_pp_oasys" {
  name                = "bridge-pp-oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-preprod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_pp_onr" {
  name                = "bridge-pp-onr"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "onr-preprod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_practice_oasys" {
  name                = "bridge-practice.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 3600
}

resource "azurerm_dns_cname_record" "bridge_training_oasys" {
  name                = "bridge-training.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 3600
}

resource "azurerm_dns_cname_record" "practice_oasys" {
  name                = "practice.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "training_oasys" {
  name                = "training.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_a_record" "aap" {
  name                = "aap"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.40.143"]
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafm" {
  name                = "cafm"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "cafm-prod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafm_preprod" {
  name                = "cafm-preprod"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "cafm-preprod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafmpmg" {
  name                = "cafmpmg"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "cafm-prod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafmpmg_preprod" {
  name                = "cafmpmg-preprod"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "cafm-preprod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "dso_monitoring_prod" {
  name                = "dso-monitoring-prod"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "ec2-35-176-103-8.eu-west-2.compute.amazonaws.com"
  ttl                 = 300
}

resource "azurerm_dns_a_record" "dev_admin_hub" {
  name                = "dev.admin.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.40.186"]
  ttl                 = 300
}

resource "azurerm_dns_a_record" "dev_hub" {
  name                = "dev.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.40.45"]
  ttl                 = 500
}

resource "azurerm_dns_a_record" "dev_jenkins_hub" {
  name                = "dev.jenkins.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.28.61"]
  ttl                 = 300
}

resource "azurerm_dns_a_record" "testing_hub" {
  name                = "testing.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.47.59"]
  ttl                 = 500
}

resource "azurerm_dns_ns_record" "licences" {
  name                = "licences"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["ns-1037.awsdns-01.org", "ns-2027.awsdns-61.co.uk", "ns-362.awsdns-45.com", "ns-673.awsdns-20.net"]
  ttl                 = 60
}

resource "azurerm_dns_cname_record" "mgmt" {
  name                = "mgmt"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "mgmt-prod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "ndelius_interface" {
  name                = "ndelius-interface"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "ndelius-prod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "offloc" {
  name                = "offloc"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "offloc-prod.azurewebsites.net"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "rsr" {
  name                = "rsr"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "rsr-prod.azurewebsites.net"
  ttl                 = 300
}
