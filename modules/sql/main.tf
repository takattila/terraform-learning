resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_mssql_server" "appserver" {
  name                         = local.appsrv_name
  resource_group_name          = azurerm_resource_group.app_grp.name
  location                     = azurerm_resource_group.app_grp.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "pass@123"

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_mssql_database" "appdb" {
  name       = "app-db"
  server_id  = azurerm_mssql_server.appserver.id
  depends_on = [azurerm_mssql_server.appserver]

  # prevent the possibility of accidental data loss?
  # (no because of learning purposes)
  lifecycle {
    prevent_destroy = false
  }
}
