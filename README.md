# Azure Terraform Learning

This repository has been crated to study terraform by the help of [Azure Infrastructure with Terraform](https://www.youtube.com/watch?v=lH3KT9RUEOA&list=PLLc2nQDXYMHowSZ4Lkq2jnZ0gsJL3ArAw) youtube playlist.

# Docs

- [Terraform Registry / Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Course GitHub page](https://github.com/cloudxeus/terraform-azure)

# GitLab Deploy pipeline

- https://gitlab.com/takattila/terraform-learning

# Usage

## Create a credentials.tfvars file in the root of the project

Content of the `credentials.tfvars` file:
```
subscription_id = "<AZURE_SUBSCRIPTION_ID>"     # Your Azure Subscription ID
client_id       = "<AZURE_ENTRA_APP_CLIENT_ID>" # Select your registered app's get its Client ID
client_secret   = "<AZURE_ENTRA_APP_SECRET"     # Select your registered app's Client credentials
tenant_id       = "<AZURE_ENTRA_APP_TENANT_ID"  # Select your registered app's Directory (tenant) ID
```

**WARNING! - For authentication purposes, please register a new app (if not registered yet) in Microsoft Entra ID. For more information, refer to the [HOWTOs section](#howtos).**

## Terraform commands

### Take control on existing infrastructure

Terraform import maps existing infrastructure (like a resource in Azure, AWS, etc.) to a resource block in your Terraform configuration, so Terraform can manage it going forward. It doesn’t create anything — it just links what's already there to your code.

```powershell
terraform import -var-file="credentials.tfvars" -input=false module.${MODULE}}$.azurerm_resource_group.app_grp "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/rg-${MODULE}}"
```

### Initialize project

```powershell
terraform init
```

### Nginx deployed by Cloud Init

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.cloud-init-nginx" -out="cloud-init-nginx.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "cloud-init-nginx.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh cloud-init-nginx

# Print output
terraform output -raw cloud_init_nginx_ssh_command
terraform output -raw cloud_init_nginx_public_ip

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.cloud-init-nginx" -auto-approve
```

### Key Vault

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.keyvault" -out="keyvault.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "keyvault.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh keyvault

# Print output
terraform output -raw keyvault_rdp_file > keyvault.rdp

# Login
explorer keyvault.rdp

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.keyvault" -auto-approve
```

### Monitor

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.monitor" -out="monitor.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "monitor.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh monitor

# Print output
terraform output monitor_service_urls
terraform output -raw monitor_ssh_command

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.monitor" -auto-approve
```

### Storage Account

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.storage" -out="storage.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "storage.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh storage

# Print output
terraform output -raw storage_sample_txt_url

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.storage" -auto-approve
```

### Linux VM

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.vm-linux" -out="vm-linux.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "vm-linux.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh vm-linux

# Print output
terraform output -raw vm_linux_ssh_command

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.vm-linux" -auto-approve
```

### Windows VM

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.vm-win" -out="vm-win.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "vm-win.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh vm-win

# Print output
terraform output -raw vm_win_rdp_file > vm-win.rdp

# Login
explorer vm-win.rdp

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.vm-win" -auto-approve
```

### WebApp

```powershell
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.webapp" -out="webapp.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "webapp.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh webapp

# Print output
terraform output -raw webapp_name
# terraform output -raw webapp_repo_url
terraform output -raw webapp_url

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.webapp" -auto-approve
```

# HOWTOs

## App registrations

Needed to authenticate terraform.

On Azure Portal,
- Go to your subscription and get the Subscription ID
- Register app in "Microsoft Entra ID" (earlier called as "Azure Active Directory")
  - Microsoft Entra ID / App registrations / New registration -> "terraform"
- In your registered app, click the Client credentials / Certificates & secrets / New client secret
  - Add a client secret

## Assign the Contributor role to an application 

To assign the Contributor role to the "terraform" application in Microsoft Entra ID (Azure AD) using the Azure Portal, follow these steps:

1. Assign a Role in Subscription:
   - In Azure Portal, navigate to Subscriptions from the left-hand menu.
   - Select the subscription where you want to assign the role.

2. Access Control (IAM):
   - Within the subscription portal, click on Access control (IAM) from the left-hand menu.
   - Click on Add role assignment to open the "Add role assignment" pane.

3. Select Contributor Role:
   - In the "Role" tab, select "Contributor" from the list and click Next.   

4. Assign to Your Application:
   - In the "Members" tab, select User, group, or service principal.
   - Click on Select members, search for and select your "terraform" application.
   - Click Select to confirm, then click Next.

5. Review and Assign:
   - In the "Review + assign" tab, review your settings.
   - Click Review + assign to apply the role.
