terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.41.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  // Configuration options
  /*
  Configuration options
  Configuration options
  */
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "ExampleRG"
  location = "West Europe"
}