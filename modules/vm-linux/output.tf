output "ssh_command" {
  description = "SSH parancs a Linux VM-hez való csatlakozáshoz"
  value       = "ssh -i projects/vm-linux/${local_file.linuxkey.filename} ${azurerm_linux_virtual_machine.vm_linux.admin_username}@${azurerm_public_ip.app_pub_ip.ip_address}"
}
