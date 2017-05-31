#This should be updated to point to the subscription and tenant that you are using

variable "azure_subscription_id" {
    type = "string"
    default = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
}
variable "azure_tenant_id" {
    type = "string"
    default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

provider "azurerm" {
    # HMPPS Digital Studio Dev & Test Environments
    subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    #HMPPS POC Evaluation Sandbox Environments
    #subscription_id = "5d8bf94e-f520-4d04-b9c5-a3a9f4735a26"
    # client_id = "..." use ARM_CLIENT_ID env var
    # client_secret = "..." use ARM_CLIENT_SECRET env var
    tenant_id = "${var.azure_tenant_id}"
}