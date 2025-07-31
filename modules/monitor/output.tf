output "monitor_service_urls" {
  description = "Monitor service URLs by IP and DNS"
  value = [
    "https://${azurerm_public_ip.public_ip.ip_address}/",
    "https://${azurerm_public_ip.public_ip.domain_name_label}.eastus.cloudapp.azure.com/"
  ]
}

output "monitor_ssh_command" {
  description = "SSH command to connect to Linux VM"
  value       = "ssh -i ${local_file.linuxkey.filename} ${azurerm_linux_virtual_machine.vm.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
  sensitive   = false
}

