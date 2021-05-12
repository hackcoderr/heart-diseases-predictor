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

resource "azurerm_public_ip" "hdp-publicip-2" {
    name                         = "Azure-HDP-PublicIP-2"
    location                     = azurerm_resource_group.hdp-rg.location
    resource_group_name          = azurerm_resource_group.hdp-rg.name
    allocation_method            = "Dynamic"

    tags = {
        Name = "HDP-Public-IP-2"
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

# Create network interfaces
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

# Create network interface
resource "azurerm_network_interface" "hdp-nic-2" {
    name                      = "myNIC-2"
    location                  = azurerm_resource_group.hdp-rg.location
    resource_group_name       = azurerm_resource_group.hdp-rg.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.hdp-subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.hdp-publicip-2.id
    }

    tags = {
        Name = "HDP-NIC-2"
        Environment = "Production"
    }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "hdp-nic-sg" {
    network_interface_id      = azurerm_network_interface.hdp-nic.id
    network_security_group_id = azurerm_network_security_group.hdp-sg.id
}


#create vm 
resource "azurerm_virtual_machine" "main-1" {
  name                  = "az-hdp-vm-1"
  location              = azurerm_resource_group.hdp-rg.location
  resource_group_name   = azurerm_resource_group.hdp-rg.name
  network_interface_ids = [azurerm_network_interface.hdp-nic.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1"
    version   = "latest"
  }
  storage_os_disk {
    name              = "hdp-disk-1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "hdpAdmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    Name = "Az-HDP-Slave-1"
    Environment = "Production"
  }
}

#create vm
resource "azurerm_virtual_machine" "main-2" {
  name                  = "az-hdp-vm-2"
  location              = azurerm_resource_group.hdp-rg.location
  resource_group_name   = azurerm_resource_group.hdp-rg.name
  network_interface_ids = [azurerm_network_interface.hdp-nic-2.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1"
    version   = "latest"
  }
  storage_os_disk {
    name              = "hdp-disk-2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "hdpAdmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    Name = "Az-HDP-Slave-2"
    Environment = "Production"
  }
}

