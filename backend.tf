terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstate12799"
    container_name       = "tfstate"
    key                  = "azure-lab.tfstate"
  }
}