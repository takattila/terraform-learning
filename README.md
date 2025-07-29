# Terraform Learning

This repository has been crated to study terraform by the help of [Azure Infrastructure with Terraform](https://www.youtube.com/watch?v=lH3KT9RUEOA&list=PLLc2nQDXYMHowSZ4Lkq2jnZ0gsJL3ArAw) youtube playlist.

# Docs

- [Terraform Registry / Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Course GitHub page](https://github.com/cloudxeus/terraform-azure)

# Usage

## Create a credentials.tfvars file in the root of the project

Content of the `credentials.tfvars` file:
```
subscription_id = "<AZURE_SUBSCRIPTION_ID>"     # Your Azure Subscription ID
client_id       = "<AZURE_ENTRA_APP_CLIENT_ID>" # Select your registered app's get its Client ID
client_secret   = "<AZURE_ENTRA_APP_SECRET"     # Select your registered app's Client credentials
tenant_id       = "<AZURE_ENTRA_APP_TENANT_ID"  # Select your registered app's Directory (tenant) ID
```

## Terraform commands

### Initialize project

```powershell
cd projects/<PROJECT_NAME>
terraform init
```

### Key Vault

```powershell
# Check changes
terraform -chdir="projects/keyvault" plan -var-file="../../credentials.tfvars" -out="keyvault.tfplan"

# Deploy resources
terraform -chdir="projects/keyvault" apply -var-file="../../credentials.tfvars" -auto-approve "keyvault.tfplan"

# Remove resources
terraform -chdir="projects/keyvault" destroy -var-file="../../credentials.tfvars" -auto-approve
```

### Storage Account

```powershell
# Check changes
terraform -chdir="projects/storage" plan -var-file="../../credentials.tfvars" -out="storage.tfplan"

# Deploy resources
terraform -chdir="projects/storage" apply -var-file="../../credentials.tfvars" -auto-approve "storage.tfplan"

# Remove resources
terraform -chdir="projects/storage" destroy -var-file="../../credentials.tfvars" -auto-approve
```

### Windows VM

```powershell
# Check changes
terraform -chdir="projects/vm-win" plan -var-file="../../credentials.tfvars" -out="vm-win.tfplan"

# Deploy resources
terraform -chdir="projects/vm-win" apply -var-file="../../credentials.tfvars" -auto-approve "vm-win.tfplan"

# Remove resources
terraform -chdir="projects/vm-win" destroy -var-file="../../credentials.tfvars" -auto-approve
```

# HOWTOs

## App registrations

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