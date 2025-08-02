locals {
  raw_ts       = timestamp()
  short_ts     = formatdate("YYMMDDhhmm", local.raw_ts)
  module_path  = path.module
  rg_name      = "rg-${basename(local.module_path)}"
  storage_name = "tformstore${local.short_ts}"
  location     = "West Europe"
  username     = "monitoruser"
  password     = "monitorpass"
}
