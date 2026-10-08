provider "azurerm" {
  features {}
  #client_id       = "<CLIENT-ID>"
  #client_secret   = "<CLIENT-SECRET>"
  #subscription_id = "<SUBSCRIPTION-ID>"
  #tenant_id       = "<TENANT-ID>"
}

data "azurerm_resource_group" "main" {
  name = "${var.prefix}-resources"
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    studentid   = "${var.prefix}"
    provider    = "terraform"
    environment = "workshop"
  }
}

# Create subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public ip
resource "azurerm_public_ip" "public-ip" {
  name                = "public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    studentid   = "${var.prefix}"
    provider    = "terraform"
    environment = "workshop"
  }
}

# Create nic
resource "azurerm_network_interface" "main" {
  name                = "instance-nic1"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip.id
  }

  tags = {
    studentid   = "${var.prefix}"
    provider    = "terraform"
    environment = "workshop"
  }
}

# Create VM
resource "azurerm_linux_virtual_machine" "default" {
  name                  = var.instance_name
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = data.azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  tags = {
    studentid   = "${var.prefix}"
    provider    = "terraform"
    environment = "workshop"
  }
}