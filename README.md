# Terraform Learning

This repository has been crated to study terraform by the help of [Azure Infrastructure with Terraform](https://www.youtube.com/watch?v=lH3KT9RUEOA&list=PLLc2nQDXYMHowSZ4Lkq2jnZ0gsJL3ArAw) youtube playlist.

# Usage

## Create a terraform.tfvars file

On Azure Portal,
- Go to your subscription and get the Subscription ID
- Register app in "Microsoft Entra ID" (earlier called as "Azure Active Directory")
  - Microsoft Entra ID / App registrations / New registration
- In your registered app, click the Client credentials / Certificates & secrets / New client secret
  - Add a client secret

Content of the `terraform.tfvars` file:
```
subscription_id = "<AZURE_SUBSCRIPTION_ID>"     # Your Azure Subscription ID
client_id       = "<AZURE_ENTRA_APP_CLIENT_ID>" # Select your registered app's get its Client ID
client_secret   = "<AZURE_ENTRA_APP_SECRET"     # Select your registered app's Client credentials
tenant_id       = "<AZURE_ENTRA_APP_TENANT_ID"  # Select your registered app's Directory (tenant) ID
```

## Terraform commands

```powershell
# Check changes
terraform plan -out main.tfplan

# Deploy resources
terraform apply .\main.tfplan

# Remove resources
terraform destroy
```