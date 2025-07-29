locals {
  raw_ts        = timestamp()
  short_ts      = formatdate("YYMMDDhhmm", local.raw_ts)
  rg_name       = "rg-keyvault"
  location      = "West Europe"
  storage_name  = "tformstore${local.short_ts}"
  keyvault_name = "keyvault${local.short_ts}"
}

data "azurerm_client_config" "current" {}
