variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "env" {
  description = "Deployment environment (e.g. dev, qa, prod)"
  type        = string
  default     = ""
}
