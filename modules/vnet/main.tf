resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_network_security_group" "app_network_sg" {
  name                = "app-network-sg"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "subnetA"
    address_prefixes = ["10.0.1.0/24"]
  }
}
