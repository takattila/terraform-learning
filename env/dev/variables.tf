variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure Client Secret"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account for the backend."
  default     = "tfbackendstorage"
}

variable "env" {
  description = "Deployment environment (e.g. dev, qa, prod)"
  type        = string
  default     = "dev"
}
