output "vm_linux_ssh_command" {
  description = "SSH command to connect to Linux VM"
  value       = "ssh -i ${local_file.linuxkey.filename} ${azurerm_linux_virtual_machine.vm_linux.admin_username}@${azurerm_public_ip.app_pub_ip.ip_address}"
}
