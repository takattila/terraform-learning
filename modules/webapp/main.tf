resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_service_plan" "webapp_plan" {
  name                = local.webapp_plan
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  os_type             = "Linux"
  sku_name            = "F1"

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_linux_web_app" "webapp" {
  name                = local.webapp_name
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  service_plan_id     = azurerm_service_plan.webapp_plan.id
  site_config {
    always_on = false
    application_stack {
      dotnet_version = "8.0"
    }
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# resource "azurerm_app_service_source_control" "github" {
#   app_id                 = azurerm_linux_web_app.webapp.id
#   repo_url               = "https://github.com/alashro/webapp.git"
#   branch                 = "master"
#   use_manual_integration = true
# }
