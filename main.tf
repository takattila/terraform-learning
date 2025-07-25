terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.37.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {}
}

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
  storage_name = "tformstore${local.short_ts}"
}

resource "azurerm_resource_group" "app_grp" {
  name     = "app-grp"
  location = "West Europe"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.app_grp.name
  location                 = "West Europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    purpose     = "learning"
    environment = "dev"
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "sample" {
  name                   = "sample.txt"
  source_content         = "Hello world!"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
}
