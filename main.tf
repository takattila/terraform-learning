module "cloud-init-nginx" {
  source = "./modules/cloud-init-nginx"
}

module "keyvault" {
  source = "./modules/keyvault"
}

module "monitor" {
  source = "./modules/monitor"
}

module "sql" {
  source = "./modules/sql"
}

module "storage" {
  source = "./modules/storage"
}

module "vm-linux" {
  source = "./modules/vm-linux"
}

module "vm-win" {
  source = "./modules/vm-win"
}

module "vnet" {
  source = "./modules/vnet"
}

module "webapp" {
  source = "./modules/webapp"
}
