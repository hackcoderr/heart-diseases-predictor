# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# creating a resource group
resource "azurerm_resource_group" "hdp-rg" {
  name     = "azure-hdg-resource-group"
  location = "Central India"
  tags = {
    Name = "Azure-HDP-RG"
    Environment = "Production"
  }
}


# creating Azure VNet

resource "azurerm_network_security_group" "hdp-sg" {
  name                = "Azure-HDP-SecurityGroup"
  location            = azurerm_resource_group.hdp-rg.location
  resource_group_name = azurerm_resource_group.hdp-rg.name
}

resource "azurerm_virtual_network" "hdp-nvet" {
  name                = "Azure-HDP-virtualNetwork"
  location            = azurerm_resource_group.hdp-rg.location
  resource_group_name = azurerm_resource_group.hdp-rg.name
  address_space       = ["192.168.0.0/16"]


  subnet {
    name           = "azure-hdp-subnet"
    address_prefix = "192.168.0.0/24"
  }


  tags = {
    Name = "Azure-HDP-VNet"
    Environment = "Production"
  }
}
