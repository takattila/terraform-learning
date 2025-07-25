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
  location     = "West Europe"
}

resource "azurerm_resource_group" "app_grp" {
  name     = "app-grp"
  location = local.location
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name             = "SubnetA"
    address_prefixes = ["10.0.1.0/24"]
  }
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
