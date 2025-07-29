output "vm_win_rdp_file" {
  description = "RDP file content for connecting to the Windows VM"
  value = <<EOT
full address:s:${azurerm_public_ip.app_pub_ip.ip_address}:3389
username:s:${azurerm_windows_virtual_machine.vm_win.admin_username}
EOT
}