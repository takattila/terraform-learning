variable "env" {
  type    = string
  default = "dev"
}

locals {
  raw_ts        = timestamp()
  short_ts      = formatdate("YYMMDDhhmm", local.raw_ts)
  module_path   = path.module
  rg_name       = "rg-${var.env}-${basename(local.module_path)}"
  location      = "West Europe"
  keyvault_name = "kv-${var.env}-${local.short_ts}"
}

data "azurerm_client_config" "current" {}
