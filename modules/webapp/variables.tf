locals {
  raw_ts      = timestamp()
  short_ts    = formatdate("YYMMDDhhmm", local.raw_ts)
  module_path = path.module
  rg_name     = "rg-${basename(local.module_path)}"
  location    = "West Europe"
  webapp_name = "webapp-${local.short_ts}"
  webapp_plan = "webapp-plan-${local.short_ts}"
}
