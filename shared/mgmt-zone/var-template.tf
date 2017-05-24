variable "azure_subscription_id" {
    type = "string"
    default = "changeme"
}
variable "azure_tenant_id" {
    type = "string"
    default = "changeme"
}
variable "azure_vault_group_oid" {
  type = "string"
  default = "changeme"
}
variable "azure_app_service_oid" {
  type = "string"
  default = "changeme"
}
variable "azure_monitoring_group_oid" {
    type = "string"
    default = "changeme"
}

// These AD ObjectIDs were found via `az ad sp list`
variable "azure_tfuser_oid" {
    type = "string"
    default = "changeme"
}
 
provider "azurerm" {
  # NOMS Digital Studio Production 1
  subscription_id = "changeme"
  # client_id = "..." use ARM_CLIENT_ID env var
  # client_secret = "..." use ARM_CLIENT_SECRET env var
  tenant_id = "${var.azure_tenant_id}"
}
