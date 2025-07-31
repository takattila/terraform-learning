module "cloud-init-nginx" {
  source = "./modules/cloud-init-nginx"
}

module "keyvault" {
  source = "./modules/keyvault"
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

module "webapp" {
  source = "./modules/webapp"
}

module "monitor" {
  source = "./modules/monitor"
}
