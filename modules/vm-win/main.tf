resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_network_watcher" "watcher" {
  name                = "app-network-watcher"
  location            = local.location
  resource_group_name = local.rg_name

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.app_network]
}

resource "azurerm_public_ip" "app_pub_ip" {
  name                = "app-pub-ip"
  resource_group_name = local.rg_name
  location            = local.location
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-nic"
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_pub_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_subnet.SubnetA,
    azurerm_public_ip.app_pub_ip
  ]
}

resource "azurerm_availability_set" "app_set" {
  name                         = "app-set"
  location                     = local.location
  resource_group_name          = local.rg_name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_windows_virtual_machine" "vm_win" {
  name                = "vm-win"
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

  depends_on = [azurerm_windows_virtual_machine.vm_win]
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm_win.id
  lun                = 0
  caching            = "ReadWrite"

  depends_on = [
    azurerm_windows_virtual_machine.vm_win,
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

  depends_on = [azurerm_windows_virtual_machine.vm_win]
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.app_interface.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id

  depends_on = [azurerm_network_security_group.vm_nsg]
}

resource "azurerm_storage_account" "appstore" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.app_grp.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    purpose     = "learning"
    environment = "dev"
  }

  depends_on = [azurerm_resource_group.app_grp]

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.appstore.id
  container_access_type = "blob"

  depends_on = [azurerm_storage_account.appstore]
}

resource "azurerm_storage_blob" "IIS_Config" {
  name                   = "IIS_Config.ps1"
  source                 = "modules/vm-win/resources/IIS_Config.ps1"
  type                   = "Block"
  storage_account_name   = azurerm_storage_account.appstore.name
  storage_container_name = azurerm_storage_container.data.name

  depends_on = [azurerm_storage_container.data]
}

resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = "appvm-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_win.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.appstore.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS

  depends_on = [azurerm_storage_blob.IIS_Config]
}
