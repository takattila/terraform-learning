resource "azurerm_resource_group" "app_grp" {
  name     = local.rg_name
  location = local.location
}

resource "azurerm_storage_account" "storage_account" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.app_grp.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on               = [azurerm_resource_group.app_grp]
  tags = {
    purpose     = "learning"
    environment = "dev"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = "blob"
  depends_on            = [azurerm_storage_account.storage_account]
}

resource "azurerm_storage_blob" "sample" {
  name                   = "sample.txt"
  source_content         = "Hello world!"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  depends_on             = [azurerm_storage_container.data]
}
