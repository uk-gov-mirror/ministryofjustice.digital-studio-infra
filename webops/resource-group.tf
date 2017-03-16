resource "azurerm_resource_group" "webops" {
  name = "webops"
  location = "ukwest"
  tags {
    Service = "WebOps"
    Environment = "Management"
  }
}
