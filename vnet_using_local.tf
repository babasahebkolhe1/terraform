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

#local variables for resource group, location, virtual network, and subnets
locals {
  resource_group_name = "myrg"
  location = "West Europe"
  virtual_network = {
    name = "vnet1"
    address_space = ["10.0.0.0/16"]
  }
}

#resource group creation using local variables
resource "azurerm_resource_group" "RG" {
  name     = local.resource_group_name
  location = local.location
}

# Virtual Network creation using local variables
# with subnets defined in the local variable
resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = local.virtual_network.address_space

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