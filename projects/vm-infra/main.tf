resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

data "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  virtual_network_name = azurerm_virtual_network.app_network.name
  resource_group_name  = local.rg_name
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name             = "SubnetA"
    address_prefixes = ["10.0.1.0/24"]
  }
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-nic"
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_virtual_network.app_network]
}

resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = "app-vm"
  resource_group_name = local.rg_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "appuser"
  admin_password      = "pass@123"
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface.app_interface]
}
