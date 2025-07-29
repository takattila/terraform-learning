module "keyvault" {
  source = "./modules/keyvault"
}

module "storage" {
  source = "./modules/storage"
}

module "vm_linux" {
  source = "./modules/vm-linux"
}

module "vm_win" {
  source = "./modules/vm-win"
}