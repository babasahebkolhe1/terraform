# This file is part of a Terraform configuration for Azure resources.
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
#depends_on ensures that the resource group is created before the virtual network
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
# This creates subnets within the virtual network
#depends_on ensures that the virtual network is created before the subnets
resource "azurerm_subnet" "subneta" {
  name = local.subnets[0].name 
  resource_group_name = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes = local.subnets[0].address_prefixe
  depends_on = [ azurerm_virtual_network.vnet ]
}

# This creates the second subnet in the virtual network
resource "azurerm_subnet" "subnetb" {
  name = local.subnets[1].name 
  resource_group_name = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes = local.subnets[1].address_prefixe
  depends_on = [ azurerm_virtual_network.vnet ]
}

# Network Interface Card (NIC) creation
# This creates a NIC that will be used by the virtual machine
resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subneta.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip1.id
  }
  depends_on = [ azurerm_subnet.subneta ]
}

# Public IP creation
# This creates a public IP address that can be associated with the NIC
resource "azurerm_public_ip" "publicip1" {
  name                = "myfirstpublicip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
  depends_on = [ azurerm_resource_group.RG ]
}

# Network Security Group (NSG) creation
# This creates a network security group that can be associated with the subnet 
# to control inbound and outbound traffic
resource "azurerm_network_security_group" "NSG" {
  name                = "mynsg1"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "rdprule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
  depends_on = [ azurerm_resource_group.RG ]
}

# NSG association with the first subnet
# This associates the created NSG with the first subnet
resource "azurerm_subnet_network_security_group_association" "nsgassociation" {
  subnet_id                 = azurerm_subnet.subneta.id
  network_security_group_id = azurerm_network_security_group.NSG.id
}