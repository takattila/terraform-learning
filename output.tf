output "cloud_init_nginx_ssh_command" {
  value = module.cloud-init-nginx.cloud_init_nginx_ssh_command
}

output "cloud_init_nginx_public_ip" {
  value = module.cloud-init-nginx.cloud_init_nginx_public_ip
}

output "storage_sample_txt_url" {
  value = module.storage.storage_sample_txt_url
}

output "vm_linux_ssh_command" {
  value = module.vm-linux.vm_linux_ssh_command
}

output "vm_win_rdp_file" {
  value = module.vm-win.vm_win_rdp_file
}
