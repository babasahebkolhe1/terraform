#terraform configuration of azure provider
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
# This allows for easier management and reuse of these values across resources
locals {
  resource_group_name = "myrg"
  location = "West Europe"
  virtual_network = {
    name = "vnet1"
    address_space = ["10.0.0.0/16"]
  }
  subnets = [
    {
      name = "subnet1"
      address_prefixe = ["10.0.1.0/24"]
    },
     {
      name = "subnet2"
      address_prefixe = ["10.0.2.0/24"]
    }
  ]
}

#resource group creation using local variables
# This creates a resource group in Azure where all resources will be deployed
resource "azurerm_resource_group" "RG" {
  name     = local.resource_group_name
  location = local.location
}

# Virtual Network creation using local variables
#depends_on ensures that the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = local.virtual_network.address_space

  depends_on = [ azurerm_resource_group.RG ]

  tags = {
    environment = "Production"
  }
}

# Subnet creation using local variables
# This creates the first subnet in the virtual network
#depends_on ensures that the virtual network is created before the subnet
resource "azurerm_subnet" "subneta" {
  name = local.subnets[0].name 
  resource_group_name = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes = local.subnets[0].address_prefixe
  depends_on = [ azurerm_virtual_network.vnet ]
}

# This creates the second subnet in the virtual network using local variables
#depends_on ensures that the virtual network is created before the subnet
resource "azurerm_subnet" "subnetb" {
  name = local.subnets[1].name 
  resource_group_name = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes = local.subnets[1].address_prefixe
  depends_on = [ azurerm_virtual_network.vnet ]
}

# Network Interface Card (NIC) creation using local variables
# This creates a network interface that can be attached to a virtual machine
# The NIC is associated with the first subnet created above
# depends_on ensures that the subnet is created before the NIC
resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subneta.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ azurerm_subnet.subneta ]
}