output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.app_network.name

}

output "subnet_name" {
  description = "Name of the Subnet"
  value       = azurerm_network_security_group.app_network_sg.name
}
