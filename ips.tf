variable "ips" {
  type = "map"

  default {
    office                = "217.33.148.210"
    quantum               = "62.25.109.197"
    health-kick           = "35.177.252.195"
    digitalprisons1       = "52.56.112.98"
    digitalprisons2       = "52.56.118.154"
    dxc                   = "109.147.195.53"
    mojvpn                = "81.134.202.29"
    j5-phones-1           = "35.177.125.252"
    j5-phones-2           = "35.177.137.160"
    sodexo-northumberland = "88.98.48.10"
    durham-tees-valley    = "51.179.193.241"
    ark-nps-hmcts-ttp1    = "195.59.75.0"
    ark-nps-hmcts-ttp2    = "195.33.192.0"
    ark-nps-hmcts-ttp3    = "195.33.193.0"
    ark-nps-hmcts-ttp4    = "195.33.196.0"
    ark-nps-hmcts-ttp5    = "195.33.197.0"
  }
}

# https://docs.microsoft.com/en-us/azure/application-insights/app-insights-ip-addresses
locals {
  azure_app_insights_ips = [
    "40.114.241.141/32",
    "104.45.136.42/32",
    "40.84.189.107/32",
    "168.63.242.221/32",
    "52.167.221.184/32",
    "52.169.64.244/32",
    "40.85.218.175/32",
    "104.211.92.54/32",
    "52.175.198.74/32",
    "23.96.28.38/32",
    "13.92.40.198/32"
  ]
}
