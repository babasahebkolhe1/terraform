#terraform provider configuration for Azure
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.36.0"
    }
  }
}

# Azure provider configuration
# Replace the empty strings with your Azure credentials
provider "azurerm" {
  subscription_id = ""
  client_id = ""
  client_secret = ""
  tenant_id = ""
  features {
    
  }
}

#resource group creation
resource "azurerm_resource_group" "RG" {
  name     = "myrg"
  location = "West Europe"
}

# Virtual Network creation
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = "West Europe"
  resource_group_name = "myrg"
  address_space       = ["10.0.0.0/16"]
  subnet {
    name             = "subnet1"
    address_prefixes = ["10.0.1.0/24"]
  }

  subnet {
    name             = "subnet2"
    address_prefixes = ["10.0.2.0/24"]
  }
  
  depends_on = [ azurerm_resource_group.RG ]

  tags = {
    environment = "Production"
  }
}
