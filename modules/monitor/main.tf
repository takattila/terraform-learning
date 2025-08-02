resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem

  depends_on = [tls_private_key.linux_key]
}

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

resource "azurerm_virtual_network" "vnet" {
  name                = "monitor-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_subnet" "subnet" {
  name                 = "monitor-subnet"
  resource_group_name  = azurerm_resource_group.app_grp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "monitor-public-ip"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "monitorservice"

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "monitor-nsg"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-7070"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7070"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-8383"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8383"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.app_grp]
}

resource "azurerm_network_interface" "nic" {
  name                = "monitor-nic"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  depends_on = [
    azurerm_subnet.subnet,
    azurerm_public_ip.public_ip
  ]
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_network_interface.nic,
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "monitor-vm"
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  size                = "Standard_B1s"
  admin_username      = local.username

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = local.username
    public_key = tls_private_key.linux_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface_security_group_association.nic_nsg_assoc,
    tls_private_key.linux_key
  ]
}

resource "null_resource" "configure_monitor" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.public_ip.ip_address
    user        = local.username
    private_key = tls_private_key.linux_key.private_key_pem
    timeout     = "2m"
  }

  provisioner "file" {
    source      = "modules/monitor/Caddyfile"
    destination = "/tmp/Caddyfile"
  }

  provisioner "file" {
    source      = "modules/monitor/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "file" {
    source      = "modules/monitor/api.linux.yaml"
    destination = "/tmp/api.linux.yaml"
  }

  provisioner "file" {
    source      = "modules/monitor/web.linux.yaml"
    destination = "/tmp/web.linux.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo === Update packages ===",
      "sudo apt update",

      "echo === Set Caddy for installation ===",
      "sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl",
      "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg",
      "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list",
      "sudo chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg",
      "sudo chmod o+r /etc/apt/sources.list.d/caddy-stable.list",

      "echo === Install Caddy ===",
      "sudo apt update",
      "sudo apt install -y caddy unzip",

      "echo === Make the script executable ===",
      "chmod +x /tmp/install.sh",

      "echo === Run the script ===",
      "/bin/bash /tmp/install.sh /opt/monitor/configs ${azurerm_public_ip.public_ip.domain_name_label}.${azurerm_resource_group.app_grp.location}.cloudapp.azure.com ${local.username} ${local.password}",

      "echo === Move Caddyfile to the correct location and configure it ===",
      "sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile",
      "sudo sed -i 's|CADDY_DOMAIN|${azurerm_public_ip.public_ip.domain_name_label}.${azurerm_resource_group.app_grp.location}.cloudapp.azure.com|g' /etc/caddy/Caddyfile",
      "sudo chown caddy:caddy /etc/caddy/Caddyfile",

      "echo === Start and enable Caddy service ===",
      "sudo systemctl enable caddy",
      "sudo systemctl restart caddy"
    ]
  }
}