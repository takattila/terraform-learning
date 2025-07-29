locals {
  raw_ts       = timestamp()
  short_ts     = formatdate("YYMMDDhhmm", local.raw_ts)
  rg_name      = "rg-storage"
  storage_name = "tformstore${local.short_ts}"
  location     = "West Europe"
}
