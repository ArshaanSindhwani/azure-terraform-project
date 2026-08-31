resource "azurerm_resource_group" "main" {
  name     = "rg-arshaan-azure-lab-dev"
  location = "eastus"

  tags = {
    environment = var.environment
  }
}