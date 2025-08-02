output "monitor_service_urls" {
  description = "Monitor service URLs by IP and DNS"
  value = [
    "http://${azurerm_public_ip.public_ip.ip_address}/",
    "http://${azurerm_public_ip.public_ip.domain_name_label}.${azurerm_resource_group.app_grp.location}.cloudapp.azure.com/"
  ]
}

output "monitor_ssh_command" {
  description = "SSH command to connect to Linux VM"
  value       = "ssh -i ${local_file.linuxkey.filename} ${local.username}@${azurerm_public_ip.public_ip.ip_address}"
  sensitive   = false
}

