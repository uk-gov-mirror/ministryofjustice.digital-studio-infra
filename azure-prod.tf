variable "azure_tenant_id" {
    type = "string"
    default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}
variable "azure_app_service_oid" {
  type = "string"
  default = "5b2509b1-64bd-4117-b839-9b0c2b02e02c"
}
variable "azure_webops_group_oid" {
    type = "string"
    default = "d37d3e52-53af-4b04-b622-75eea2ee643a"
}

// These AD ObjectIDs were found via `az ad sp list`
variable "azure_glenm_tfprod_oid" {
    type = "string"
    default = "ad1a039a-c546-4a8f-b5ac-9ce4079b1e92"
}

provider "azurerm" {
  # NOMS Digital Studio Production 1
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
  # client_id = "..." use ARM_CLIENT_ID env var
  # client_secret = "..." use ARM_CLIENT_SECRET env var
  tenant_id = "${var.azure_tenant_id}"
}
