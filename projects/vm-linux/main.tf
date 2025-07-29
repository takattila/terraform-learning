resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# We want to save the private key to our machine
# We can then use this key to connect to our Linux VM

resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem
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

resource "azurerm_network_interface" "app_nic" {
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

resource "azurerm_linux_virtual_machine" "vm_linux" {
  name                = "vm-linux"
  resource_group_name = local.rg_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "linuxuser"
  custom_data         = data.template_cloudinit_config.linuxconfig.rendered
  network_interface_ids = [
    azurerm_network_interface.app_nic.id,
  ]

  admin_ssh_key {
    username   = "linuxuser"
    public_key = tls_private_key.linux_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_nic,
    tls_private_key.linux_key,
    local_file.linuxkey,
  ]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = local.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_linux_virtual_machine.vm_linux]
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.app_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id

  depends_on = [azurerm_network_security_group.vm_nsg]
}
