output "sql_database_id" {
  value = azurerm_mssql_database.appdb.id
}

output "sql_database_url" {
  value = azurerm_mssql_server.appserver.fully_qualified_domain_name
}

output "sql_jdbc_connection_string" {
  value     = "jdbc:sqlserver://${azurerm_mssql_server.appserver.fully_qualified_domain_name}:1433;database=${azurerm_mssql_database.appdb.name};user=${azurerm_mssql_server.appserver.administrator_login};password=${azurerm_mssql_server.appserver.administrator_login_password};encrypt=true;trustServerCertificate=false;loginTimeout=30;"
  sensitive = true
}
