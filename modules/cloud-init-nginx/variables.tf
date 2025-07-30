locals {
  raw_ts       = timestamp()
  short_ts     = formatdate("YYMMDDhhmm", local.raw_ts)
  rg_name      = "rg-cloud-init-nginx"
  location     = "West Europe"
  storage_name = "tformstore${local.short_ts}"
}

data "template_cloudinit_config" "linuxconfig" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "packages: ['nginx']"
  }
}
