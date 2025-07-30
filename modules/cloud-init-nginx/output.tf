output "cloud_init_nginx_ssh_command" {
  description = "SSH command to connect to Linux VM"
  value       = "ssh -i ${local_file.linuxkey.filename} ${azurerm_linux_virtual_machine.vm_linux.admin_username}@${azurerm_public_ip.app_pub_ip.ip_address}"
}

output "cloud_init_nginx_public_ip" {
  description = "The public IP of the Linux VM -> Nginx server landing page"
  value       = "http://${azurerm_public_ip.app_pub_ip.ip_address}"
}
