variable "env" {
  type    = string
  default = "dev"
}

locals {
  raw_ts      = timestamp()
  short_ts    = formatdate("YYMMDDhhmm", local.raw_ts)
  module_path = path.module
  rg_name     = "rg-${var.env}-${basename(local.module_path)}"
  location    = "West Europe"
}

data "template_cloudinit_config" "linuxconfig" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "packages: ['nginx']"
  }
}
