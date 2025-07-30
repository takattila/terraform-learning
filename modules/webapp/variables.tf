locals {
  raw_ts      = timestamp()
  short_ts    = formatdate("YYMMDDhhmm", local.raw_ts)
  rg_name     = "rg-webapp"
  location    = "West Europe"
  webapp_name = "webapp-${local.short_ts}"
  webapp_plan = "webapp-plan-${local.short_ts}"
}
