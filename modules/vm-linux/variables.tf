variable "env" {
  type    = string
  default = "dev"
}

locals {
  module_path = path.module
  rg_name     = "rg-${var.env}-${basename(local.module_path)}"
  location    = "West Europe"
}
