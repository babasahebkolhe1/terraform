# Terraform configuration for Azure provider and resources
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.36.0"
    }
  }
}

# Configure the AzureRM provider
# Replace with your Azure subscription details  
# Ensure you have the necessary permissions to create resources in the specified subscription
# You can also use environment variables for sensitive information  
# such as client_id, client_secret, and tenant_id
# Note: The subscription_id is optional if you have only one subscription
provider "azurerm" {
  subscription_id = ""
  client_id = ""
  client_secret = ""
  tenant_id = ""
  features {
    
  }
}

# Create a resource group
# This resource group will contain all other resources
# Ensure the name is unique within your Azure subscription
# The location should be a valid Azure region, e.g., "West Europe", "East US", etc.
## The resource group is a logical container for resources
# It helps in managing and organizing resources in Azure
resource "azurerm_resource_group" "RG" {
  name     = "myrg"
  location = "West Europe"
}

# Create a storage account
# The storage account is used to store blobs, files, queues, and tables
# Ensure the name is globally unique across Azure
# The account_tier can be "Standard" or "Premium"
# The account_replication_type can be "LRS", "GRS", "RAGRS", etc.
# LRS (Locally Redundant Storage) is the most common type
# The storage account must be created in the same region as the resource group
#it depends on the resource group created above
resource "azurerm_storage_account" "storage" {
  name                     = "tgstorage12345"
  resource_group_name      = "myrg"
  location                 = "West Europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [ azurerm_resource_group.RG ]

}

# Create a storage container
# The storage container is used to organize blobs within the storage account
# Ensure the name is lowercase and unique within the storage account
# The container_access_type can be "private", "blob", or "container"
# "private" means the container is not accessible publicly
# "blob" means blobs are accessible publicly, but the container is not

resource "azurerm_storage_container" "container" {
  name                  = "container1"
  storage_account_name    = "tgstorage12345"
  container_access_type = "container"
  depends_on = [ azurerm_storage_account.storage ]
}

# Create a storage blob
# The storage blob is a file stored in the storage container
# Ensure the name is unique within the container
# The type can be "Block", "Page", or "Append"
# "Block" blobs are used for most scenarios, such as text and binary files
resource "azurerm_storage_blob" "blob" {
  name                   = "new123"
  storage_account_name   = "tgstorage12345"
  storage_container_name = "container1"
  type                   = "Block"
  source                 = "main.tf"
  depends_on = [ azurerm_storage_container.container ]
}
