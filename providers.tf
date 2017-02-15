provider "azurerm" {
  # NOMS Digital Studio Dev & Test Environments
  subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  # client_id = "..." use ARM_CLIENT_ID env var
  # client_secret = "..." use ARM_CLIENT_SECRET env var
  tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

provider "heroku" {
  # email = "..." use HEROKU_EMAIL env var
  # api_key = "..." use HEROKU_API_KEY env var
}
