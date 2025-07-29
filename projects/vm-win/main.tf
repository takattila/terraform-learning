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

resource "azurerm_public_ip" "app_pub_ip" {
  name                = "app-pub-ip"
  resource_group_name = local.rg_name
  location            = local.location
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.app_grp]
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-nic"
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_pub_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_pub_ip
  ]
}

resource "azurerm_availability_set" "app_set" {
  name                         = "app-set"
  location                     = local.location
  resource_group_name          = local.rg_name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3
}

resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = "app-vm"
  resource_group_name = local.rg_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "appuser"
  admin_password      = "pass@123"
  availability_set_id = azurerm_availability_set.app_set.id
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

  depends_on = [
    azurerm_network_interface.app_interface,
    azurerm_availability_set.app_set
  ]
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "data-disk"
  location             = local.location
  resource_group_name  = local.rg_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 16

  depends_on = [azurerm_windows_virtual_machine.app_vm]
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.app_vm.id
  lun                = 0
  caching            = "ReadWrite"

  depends_on = [
    azurerm_windows_virtual_machine.app_vm,
    azurerm_managed_disk.data_disk
  ]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = local.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_windows_virtual_machine.app_vm]
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.app_interface.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id

  depends_on = [azurerm_network_security_group.vm_nsg]
}
