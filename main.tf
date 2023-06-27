terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.6"
    }

  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_resource_group" "rg-aula" {
  name     = "rg-aula"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "vnet-aula" {
  name                = "vnet-aula"
  location            = azurerm_resource_group.rg-aula.location
  resource_group_name = azurerm_resource_group.rg-aula.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    faculdade   = "Impacta"
    environment = "Production"
  }
}

resource "azurerm_subnet" "sub-aula" {
  name                 = "sub-aula"
  resource_group_name  = azurerm_resource_group.rg-aula.name
  virtual_network_name = azurerm_virtual_network.vnet-aula.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip-aula" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.rg-aula.name
  location            = azurerm_resource_group.rg-aula.location
  allocation_method   = "Static"

  tags = {
    faculdade = "Impacta"
  }
}

resource "azurerm_network_security_group" "nsg-aula" {
  name                = "nsg-aula"
  location            = azurerm_resource_group.rg-aula.location
  resource_group_name = azurerm_resource_group.rg-aula.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Web"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    faculdade   = "Impacta"
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic-aula" {
  name                = "nic-aula"
  location            = azurerm_resource_group.rg-aula.location
  resource_group_name = azurerm_resource_group.rg-aula.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-aula.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-aula.id
  }

  tags = {
    faculdade   = "Impacta"
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-aula" {
  network_interface_id      = azurerm_network_interface.nic-aula.id
  network_security_group_id = azurerm_network_security_group.nsg-aula.id
}

resource "azurerm_linux_virtual_machine" "vm-aula" {
  name                             = "example-machine"
  resource_group_name              = azurerm_resource_group.rg-aula.name
  location                         = azurerm_resource_group.rg-aula.location
  size                             = "Standard_DS1_v2"
  admin_username                   = "adminuser"
  admin_password                   = "Teste@admin123!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic-aula.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }
}
