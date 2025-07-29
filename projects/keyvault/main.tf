data "azurerm_client_config" "current" {}

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

resource "azurerm_windows_virtual_machine" "vm_win" {
  name                = "vm-win"
  resource_group_name = local.rg_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "appuser"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
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
    azurerm_key_vault_secret.vmpassword
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

resource "azurerm_key_vault" "app_vault" {
  name                       = local.keyvault_name
  location                   = local.location
  resource_group_name        = local.rg_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
    storage_permissions = [
      "Get",
    ]
  }
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = "pass@123"
  key_vault_id = azurerm_key_vault.app_vault.id
  depends_on   = [azurerm_key_vault.app_vault]
}
