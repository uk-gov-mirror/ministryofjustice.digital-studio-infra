variable "app-name" {
  type    = "string"
  default = "licences-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Licences"
    Environment = "PreProd"
  }
}

variable "pdf-gen-app-name" {
  type    = "string"
  default = "licences-pdf-generator-preprod"
}

variable "pdf-gen-tags" {
  type = "map"

  default {
    Service     = "licences-pdf-generator"
    Environment = "PreProd"
  }
}


# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "1"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/api"
  api_client_id       = "licences"
}

# Azure config
locals {
  azurerm_resource_group = "licences-preprod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
