output "cloud_init_nginx_ssh_command" {
  value = module.cloud-init-nginx.cloud_init_nginx_ssh_command
}

output "cloud_init_nginx_public_ip" {
  value = module.cloud-init-nginx.cloud_init_nginx_public_ip
}

output "monitor_service_urls" {
  value = module.monitor.monitor_service_urls
}

output "monitor_ssh_command" {
  value = module.monitor.monitor_ssh_command
}

output "sql_database_id" {
  value = module.sql.sql_database_id
}

output "sql_database_url" {
  value = module.sql.sql_database_url
}

output "sql_jdbc_connection_string" {
  value     = module.sql.sql_jdbc_connection_string
  sensitive = true
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

output "vnet_name" {
  value = module.vnet.vnet_name
}

output "subnet_name" {
  value = module.vnet.subnet_name
}

output "webapp_name" {
  value = module.webapp.webapp_name
}

# output "webapp_repo_url" {
#   value = module.webapp.webapp_repo_url
# }

output "webapp_url" {
  value = module.webapp.webapp_url
}
