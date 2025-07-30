output "webapp_name" {
  description = "Name of the web app"
  value       = azurerm_linux_web_app.webapp.name

}

# output "webapp_repo_url" {
#   description = "Repository URL for the web app"
#   value       = azurerm_app_service_source_control.github.repo_url

# }

output "webapp_url" {
  description = "Public URL for the web app"
  value       = "https://${azurerm_linux_web_app.webapp.default_hostname}"
}
