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
variable "azure_glenm_tf_oid" {
    type = "string"
    default = "c130dee7-0e83-4a95-ad2f-e90864052eb8"
}
variable "azure_robl_tf_oid" {
    type = "string"
    default = "f8ad600e-d143-4d29-a77d-c411a1534b6e"
}

provider "azurerm" {
    # NOMS Digital Studio Dev & Test Environments
    subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    # client_id = "..." use ARM_CLIENT_ID env var
    # client_secret = "..." use ARM_CLIENT_SECRET env var
    tenant_id = "${var.azure_tenant_id}"
}
