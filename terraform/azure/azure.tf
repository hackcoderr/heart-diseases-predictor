# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "hdp-rg" {
    name     = "Azure-HDP-ResourceGroup"
    location = "Central India"

    tags = {
        Name = "Azure-HDP-RG"
        environment = "Production"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "hdp-vnet" {
    name                = "Azure-HDP-Vnet"
    address_space       = ["192.168.0.0/16"]
    location            = azurerm_resource_group.hdp-rg.location
    resource_group_name = azurerm_resource_group.hdp-rg.name

    tags = {
        Name = "Azure-HDP-VNet"
        environment = "Production"
    }
}

# Create subnet
resource "azurerm_subnet" "hdp-subnet" {
    name                 = "Azure-HDP-Subnet"
    resource_group_name  = azurerm_resource_group.hdp-rg.name
    virtual_network_name = azurerm_virtual_network.hdp-vnet.name
    address_prefixes       = ["192.168.0.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "hdp-publicip" {
    name                         = "Azure-HDP-PublicIP"
    location                     = azurerm_resource_group.hdp-rg.location
    resource_group_name          = azurerm_resource_group.hdp-rg.name
    allocation_method            = "Dynamic"

    tags = {
        Name = "HDP-Public-IP"
        environment = "Production"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "hdp-sg" {
    name                = "Azure-HDP-SG"
    location            = azurerm_resource_group.hdp-rg.location
    resource_group_name = azurerm_resource_group.hdp-rg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        Name = "Azure-HDP-SG"
        environment = "Production"
    }
}

# Create network interface
resource "azurerm_network_interface" "hdp-nic" {
    name                      = "myNIC"
    location                  = azurerm_resource_group.hdp-rg.location
    resource_group_name       = azurerm_resource_group.hdp-rg.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.hdp-subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.hdp-publicip.id
    }

    tags = {
        Name = "HDP-NIC"
        Environment = "Production"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "hdp-nic-sg" {
    network_interface_id      = azurerm_network_interface.hdp-nic.id
    network_security_group_id = azurerm_network_security_group.hdp-sg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.hdp-rg.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "hdp-storageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.hdp-rg.name
    location                    = azurerm_resource_group.hdp-rg.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        Name = "HDP-Storage-Account"
        environment = "Production"
    }
}

