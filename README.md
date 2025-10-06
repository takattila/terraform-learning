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
```bash
subscription_id = "<AZURE_SUBSCRIPTION_ID>"     # Your Azure Subscription ID
client_id       = "<AZURE_ENTRA_APP_CLIENT_ID>" # Select your registered app's get its Client ID
client_secret   = "<AZURE_ENTRA_APP_SECRET"     # Select your registered app's Client credentials
tenant_id       = "<AZURE_ENTRA_APP_TENANT_ID"  # Select your registered app's Directory (tenant) ID
```

**WARNING! - For authentication purposes, please register a new app (if not registered yet) in Microsoft Entra ID. For more information, refer to the [HOWTOs section](#howtos).**

## Terraform commands

### Initialize project

```bash
terraform init
```

### Create backend infrastructure

Before you can use the modules, you need to create the backend infrastructure.
<br>The backend infrastructure is managed by the `infra/backend` module.

This process is automated by the `scripts/backend.sh` script.

The script will:
1. Create the backend infrastructure using the `infra/backend` module -> will create a storage account with a random name.
2. Generate the `backend.tf` file in the root of the project with the correct `storage_account_name`.

To run the script:
```bash
bash scripts/backend.sh
```

After running the script, you can initialize the main project:
```bash
terraform init
```

### Destroy backend infrastructure

To destroy the backend infrastructure run the script with the `destroy` argument:

```bash
bash scripts/backend.sh destroy
```

### Nginx deployed by Cloud Init

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

### SQL

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.sql" -out="sql.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "sql.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh sql

# Print output
terraform output -raw sql_database_id
terraform output -raw sql_database_url
terraform output -raw sql_jdbc_connection_string

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.sql" -auto-approve
```

### Storage Account

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

### Vnet

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
# Check changes
terraform plan -var-file="credentials.tfvars" -target="module.vnet" -out="vnet.tfplan"

# Deploy resources
terraform apply -var-file="credentials.tfvars" -auto-approve "vnet.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh vnet

# Print output
terraform output -raw vnet_name
terraform output -raw subnet_name

# Remove resources
terraform destroy -var-file="credentials.tfvars" -target="module.vnet" -auto-approve
```

### WebApp

**Note:** Before deploying this module, make sure you have created the backend infrastructure as described above.

```bash
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

## Take control on existing infrastructure

Terraform import maps existing infrastructure (like a resource in Azure, AWS, etc.) to a resource block in your Terraform configuration, so Terraform can manage it going forward. It doesn’t create anything — it just links what's already there to your code.

```bash
terraform import -var-file="credentials.tfvars" -input=false module.${MODULE}}$.azurerm_resource_group.app_grp "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/rg-${MODULE}}"
```

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

# Differences between ARM templates and Terraform

## Comparison

| Feature                   | ARM Templates                         | Terraform                                           |
|---------------------------|---------------------------------------|-----------------------------------------------------|
| Language                  | JSON                                  | HashiCorp Configuration Language (HCL)              |
| Comments                  | Limited (metadata only)               | Supports inline comments (#)                        |
| Syntax                    | Strict, less forgiving                | More forgiving, easier to read                      |
| Parameters                | Parameters (passed values)            | Variables (passed values)                           |
| Variables (internal)      | Variables in template                 | Local variables                                     |
| Resource referencing      | `reference` function or concatenation | Resource addressing                                 |
| Dependency management     | Must explicitly declare dependencies  | Automatically infers dependencies                   |
| Reuse of templates        | Nested template references            | Modules                                             |
| Functions for resources   | Functions for strings, numbers, dates | Easier referencing with HCL                         |
| Flexibility and ease of use| More rigid, explicit configuration   | More flexible, simpler syntax, automatic management |

## Differences

- ARM templates use JSON language, while Terraform uses HashiCorp Configuration Language (HCL), which supports comments and is more human-readable and forgiving in syntax.
- ARM templates have parameters (values passed into templates) and variables (values defined inside the template), whereas Terraform calls parameters variables and ARM's variables are called local variables in Terraform.
- Both handle resources like virtual machines, networks, and storage but differ in syntax and ease of resource referencing; Terraform offers easier resource referencing due to HCL's user-friendly structure.
- Dependency management differs significantly: ARM requires explicit dependency declarations (e.g., VM depends on NIC), while Terraform automatically infers dependencies with a dependency graph, simplifying configuration.
- To reference resources in ARM, functions like reference or string concatenations are used; Terraform simplifies this with resource addressing and data sources for external information.
- ARM templates use nested template references to reuse components; Terraform uses modules to achieve similar reuse but in a more modular and flexible way.
- Overall, moving from ARM templates to Terraform requires learning new terminology and concepts but offers benefits like simpler syntax, automatic dependency handling, and more flexible infrastructure management.

# When it is suitable to use ARM templates versus Terraform

## ARM templates

Are best used when working exclusively within the Azure ecosystem and needing native support for the latest Azure features immediately after release. They offer deep integration with Azure services, including built-in Role-Based Access Control (RBAC), detailed error messaging, and native support in the Azure Portal for managing deployments. ARM templates are ideal for scenarios where using Microsoft's native tools and direct Azure service integrations are priorities.

## Terraform

Is preferable when managing multi-cloud environments or hybrid setups, as it supports a wide range of cloud providers beyond Azure. It offers a simpler, modular, and more readable configuration language (HCL) and automatically handles dependencies, making infrastructure management easier for complex setups. Terraform supports state management enabling incremental changes, and benefits from a vibrant community providing numerous modules and providers, enhancing flexibility and portability.

## In summary

If the infrastructure is purely Azure-focused and deep native integration, visibility, and control are required, ARM templates are recommended. If flexibility, multi-cloud support, modularity, and ease of use in managing complex infrastructures are needed, Terraform is the better choice. Organizations sometimes use both, leveraging ARM templates for Azure-native features and Terraform for broader infrastructure provisioning.