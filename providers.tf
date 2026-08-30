terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state is deliberately not configured with a local backend.
  # In a real deployment this block points at an Azure Storage container
  # so state is shared, locked, and never committed to source control.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstateshared"
  #   container_name       = "tfstate"
  #   key                  = "platform-demo.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
