module "cloud-init-nginx" {
  source = "../../modules/cloud-init-nginx"
  env    = var.env
}

module "keyvault" {
  source = "../../modules/keyvault"
  env    = var.env
}

module "monitor" {
  source = "../../modules/monitor"
  env    = var.env
}

module "sql" {
  source = "../../modules/sql"
  env    = var.env
}

module "storage" {
  source = "../../modules/storage"
  env    = var.env
}

module "vm-linux" {
  source = "../../modules/vm-linux"
  env    = var.env
}

module "vm-win" {
  source = "../../modules/vm-win"
  env    = var.env
}

module "vnet" {
  source = "../../modules/vnet"
  env    = var.env
}

module "webapp" {
  source = "../../modules/webapp"
  env    = var.env
}
