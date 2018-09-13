variable "app-name" {
  type    = "string"
  default = "licences-stage2"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Licences"
    Environment = "Stage"
  }
}

variable "pdf-gen-app-name" {
  type    = "string"
  default = "licences-pdf-generator-stage2"
}

variable "pdf-gen-tags" {
  type = "map"

  default {
    Service     = "licences-pdf-generator-2"
    Environment = "stage"
  }
}


# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api"
  api_client_id       = "licences"
}

# Azure config
locals {
  azurerm_resource_group = "licences-stage2"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
