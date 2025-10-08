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
  webapp_name = "webapp-${var.env}-${local.short_ts}"
  webapp_plan = "webapp-plan-${var.env}-${local.short_ts}"
}
