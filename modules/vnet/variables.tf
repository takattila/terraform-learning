locals {
  module_path = path.module
  rg_name     = "rg-${basename(local.module_path)}"
  location    = "West Europe"
}
