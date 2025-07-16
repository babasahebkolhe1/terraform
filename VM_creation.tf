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
# This creates subnets within the virtual network using the defined local variables
resource "azurerm_subnet" "subneta" {
  name = local.subnets[0].name 
  resource_group_name = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes = local.subnets[0].address_prefixe
  depends_on = [ azurerm_virtual_network.vnet ]
}

# This creates the second subnet in the virtual network
# It uses the second entry in the local subnets list
resource "azurerm_subnet" "subnetb" {
  name = local.subnets[1].name 
  resource_group_name = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes = local.subnets[1].address_prefixe
  depends_on = [ azurerm_virtual_network.vnet ]
}

# Network Interface Card (NIC) creation
# This creates a NIC that can be attached to a virtual machine
# This NIC will be associated with the first subnet created above
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
# It uses a static allocation method
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
# This creates a network security group to control inbound and outbound traffic
# It includes a rule to allow RDP traffic on port 3389
#depends_on ensures that the resource group is created before the NSG
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

# Association of NSG with the first subnet
# This links the NSG to the first subnet created above
# This ensures that the security rules defined in the NSG apply to the subnet
resource "azurerm_subnet_network_security_group_association" "nsgassociation" {
  subnet_id                 = azurerm_subnet.subneta.id
  network_security_group_id = azurerm_network_security_group.NSG.id
}

# Virtual Machine creation
# This creates a Windows virtual machine in the specified resource group and location
# It uses the NIC created above and applies the NSG to the VM's network interface
# The VM is configured with a standard size and an admin username and password
# The OS disk is set to use Standard_LRS storage
#depends_on ensures that the NIC and resource group are created before the VM
resource "azurerm_windows_virtual_machine" "windowsVM" {
  name                = "TG-VM1"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Pass@1234"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_network_interface.nic, azurerm_resource_group.RG ]
}