

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure Client Secret"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

locals {
  raw_ts       = timestamp()
  short_ts     = formatdate("YYMMDDhhmm", local.raw_ts)
  rg_name      = "rg-vm-linux"
  location     = "West Europe"
  storage_name = "tformstore${local.short_ts}"
}

data "azurerm_client_config" "current" {}

data "template_cloudinit_config" "linuxconfig" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "packages: ['nginx']"
  }
}