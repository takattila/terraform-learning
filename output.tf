output "keyvault_rdp_file" {
  value = module.keyvault.keyvault_rdp_file
}

output "sample_txt_url" {
  value = module.storage.sample_txt_url
}

output "ssh_command" {
  value = module.vm_linux.ssh_command
}

output "vm_win_rdp_file" {
  value = module.vm_win.vm_win_rdp_file
}