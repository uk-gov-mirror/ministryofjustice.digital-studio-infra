variable "app-name" {
  type    = "string"
  default = "keyworker-api-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Prod"
  }
}

locals {
  elite2_uri_root = "https://gateway.nomis-api.service.justice.gov.uk/elite2api"
}
