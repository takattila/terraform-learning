locals {
  raw_ts       = timestamp()
  short_ts     = formatdate("YYMMDDhhmm", local.raw_ts)
  rg_name      = "rg-vm-linux"
  location     = "West Europe"
  storage_name = "tformstore${local.short_ts}"
}
