# Azure Terraform Learning

This repository was created to study Terraform using the [Azure Infrastructure with Terraform](https://www.youtube.com/watch?v=lH3KT9RUEOA&list=PLLc2nQDXYMHowSZ4Lkq2jnZ0gsJL3ArAw) YouTube playlist.

## 📚 Documentation

- [Terraform Registry / Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Course GitHub page](https://github.com/cloudxeus/terraform-azure)

## 🚀 GitLab Deploy Pipeline

- https://gitlab.com/takattila/terraform-learning

---

## 🚀 GitHub Actions CI Pipeline

This repository uses GitHub Actions to automatically run `terraform plan & fmt & validate` for each environment (`dev`, `qa`, `prod`) when changes are pushed or a pull request is created targeting the `main` branch.

The workflow is defined in `.github/workflows/main.yaml` and is triggered by modifications in the `modules/`, `env/`, or `.github/workflows/` directories. This process helps validate the Terraform configuration and allows for a review of potential changes before they are applied.

---

## 🔐 Credentials Setup

Create a `credentials.tfvars` file in the root of the project:

```hcl
subscription_id = "<AZURE_SUBSCRIPTION_ID>"     # Your Azure Subscription ID
client_id       = "<AZURE_ENTRA_APP_CLIENT_ID>" # App registration Client ID
client_secret   = "<AZURE_ENTRA_APP_SECRET>"    # App registration Client Secret
tenant_id       = "<AZURE_ENTRA_APP_TENANT_ID>" # App registration Tenant ID
```

⚠️ For authentication, register an app in Microsoft Entra ID. See [HOWTOs](#howtos) for details.

---

## ⚙️ Terraform Workflow


### 1. Backend Infrastructure

Managed by the `infra/backend` module. Use the script:

```bash
bash scripts/backend.sh dev

# To destroy:
bash scripts/backend.sh destroy
```

---

### 2. Initialize project

```bash
terraform -chdir="env/dev" init -reconfigure
```

---

## 📦 Module Deployment

Each module follows the same pattern:

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.<module>" -out="<module>.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "<module>.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh <module> dev

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.<module>" -auto-approve
```

---

### 🌐 Cloud Init Nginx

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.cloud-init-nginx" -out="cloud-init-nginx.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "cloud-init-nginx.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh cloud-init-nginx dev

# Print output
terraform -chdir="env/dev" output -raw cloud_init_nginx_ssh_command
terraform -chdir="env/dev" output -raw cloud_init_nginx_public_ip

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.cloud-init-nginx" -auto-approve
```

### 🔐 Key Vault

```bash

# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.keyvault" -out="keyvault.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "keyvault.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh keyvault dev

# Print output
terraform -chdir="env/dev" output -raw keyvault_rdp_file > keyvault.rdp

# Login
explorer keyvault.rdp

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.keyvault" -auto-approve
```

### 📊 Monitor

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.monitor" -out="monitor.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "monitor.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh monitor dev

# Print output
terraform -chdir="env/dev" output monitor_service_urls
terraform -chdir="env/dev" output -raw monitor_ssh_command

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.monitor" -auto-approve
```

### 🗄️ SQL

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.sql" -out="sql.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "sql.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh sql dev

# Print output
terraform -chdir="env/dev" output -raw sql_database_id
terraform -chdir="env/dev" output -raw sql_database_url
terraform -chdir="env/dev" output -raw sql_jdbc_connection_string

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.sql" -auto-approve
```

### 📦 Storage Account

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.storage" -out="storage.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "storage.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh storage dev

# Print output
terraform -chdir="env/dev" output -raw storage_sample_txt_url

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.storage" -auto-approve
```

### 🐧 Linux VM

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.vm-linux" -out="vm-linux.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "vm-linux.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh vm-linux dev

# Print output
terraform -chdir="env/dev" output -raw vm_linux_ssh_command

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.vm-linux" -auto-approve
```

### 🪟 Windows VM

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.vm-win" -out="vm-win.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "vm-win.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh vm-win dev

# Print output
terraform -chdir="env/dev" output -raw vm_win_rdp_file > vm-win.rdp

# Login
explorer vm-win.rdp

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.vm-win" -auto-approve
```

### 🌐 Vnet

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.vnet" -out="vnet.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "vnet.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh vnet dev

# Print output
terraform -chdir="env/dev" output -raw vnet_name
terraform -chdir="env/dev" output -raw subnet_name

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.vnet" -auto-approve
```

---

### 🌍 WebApp

```bash
# Check changes
terraform -chdir="env/dev" plan -var-file="../../credentials.tfvars" -target="module.webapp" -out="webapp.tfplan"

# Deploy resources
terraform -chdir="env/dev" apply -auto-approve "webapp.tfplan"

# Alternatively you can use scripts/apply.sh
bash scripts/apply.sh webapp dev

# Print output
terraform -chdir="env/dev" output -raw webapp_name
terraform -chdir="env/dev" output -raw webapp_url

# Remove resources
terraform -chdir="env/dev" destroy -var-file="../../credentials.tfvars" -target="module.webapp" -auto-approve
```

---

## HOWTOs

### 🔄 Import existing infrastructure

Use Terraform import to link existing Azure resources to your Terraform configuration:

```bash
terraform import -var-file="../../credentials.tfvars" -var="env=dev" -input=false module.${MODULE}.azurerm_resource_group.app_grp "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/rg-${MODULE}-${ENV}"
```

---

### 🔐 App registration in Microsoft Entra ID

1. Go to Azure Portal → Microsoft Entra ID → App registrations → New registration → Name it `terraform`
2. After registration:
   - Get the Client ID
   - Create a Client Secret
   - Get the Tenant ID

---

### 👤 Assign Contributor role to the app

1. Go to Azure Portal → Subscriptions → Select your subscription
2. Access Control (IAM) → Add role assignment
3. Select **Contributor** role
4. Assign to your registered app (`terraform`)
5. Review and assign

---

## 🧠 ARM Templates vs Terraform

| Feature                   | ARM Templates                         | Terraform                                           |
|---------------------------|---------------------------------------|-----------------------------------------------------|
| Language                  | JSON                                  | HCL                                                 |
| Comments                  | Limited                               | Inline comments supported                           |
| Syntax                    | Strict                                | Forgiving and readable                              |
| Parameters                | Parameters                            | Variables                                           |
| Internal variables        | Template variables                    | Locals                                              |
| Resource referencing      | `reference()` or concat               | Direct addressing                                   |
| Dependency management     | Manual                                | Automatic                                           |
| Reuse                     | Nested templates                      | Modules                                             |
| Functions                 | Limited                               | Rich HCL functions                                  |
| Flexibility               | Rigid                                 | Modular and flexible                                |

---

## ✅ When to use what

- Use **ARM templates** for deep Azure integration and immediate feature support.
- Use **Terraform** for multi-cloud, modularity, and easier infrastructure management.
