variable "azure_tenant_id" {
    type = "string"
    default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

provider "azurerm" {
  # NOMS Digital Studio Production 1
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
  # client_id = "..." use ARM_CLIENT_ID env var
  # client_secret = "..." use ARM_CLIENT_SECRET env var
  tenant_id = "${var.azure_tenant_id}"
}
