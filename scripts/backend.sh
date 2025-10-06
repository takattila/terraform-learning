#!/bin/bash

set -euo pipefail

# Define paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/infra/backend"
TFVARS_FILE="$ROOT_DIR/credentials.tfvars"
BACKEND_TF="$ROOT_DIR/backend.tf"

# Logging helpers
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Exit with error message
exit_with_error() {
    log_error "$1"
    exit 1
}

# Initialize Terraform backend module
initialize_backend() {
    log_info "Initializing Terraform backend module..."
    terraform -chdir="$BACKEND_DIR" init -upgrade
}

# Apply backend infrastructure
apply_backend() {
    log_info "Applying backend infrastructure..."
    if [ ! -f "$TFVARS_FILE" ]; then
        exit_with_error "Missing credentials file: $TFVARS_FILE"
    fi
    terraform -chdir="$BACKEND_DIR" apply -var-file="$TFVARS_FILE" -auto-approve
}

# Destroy backend infrastructure
destroy_backend() {
    log_info "Destroying backend infrastructure..."
    if [ ! -f "$TFVARS_FILE" ]; then
        exit_with_error "Missing credentials file: $TFVARS_FILE"
    fi
    terraform -chdir="$BACKEND_DIR" destroy -var-file="$TFVARS_FILE" -auto-approve
    
    if [ -f "$BACKEND_TF" ]; then
        log_info "Removing backend.tf..."
        rm -f "$BACKEND_TF"
    fi
    
    log_info "Backend infrastructure destroyed and backend.tf removed."
}

# Retrieve storage account name from Terraform output
get_storage_account_name() {
    terraform -chdir="$BACKEND_DIR" output -raw storage_account_name || exit_with_error "Output 'storage_account_name' is empty or unavailable."
}

# Generate backend.tf file in project root
generate_backend_tf() {
    local storage_account_name
    
    log_info "Retrieving storage account name..."
    storage_account_name=$(get_storage_account_name)
    
    log_info "Generating backend.tf with storage account: $storage_account_name"
    cat <<EOF > "$BACKEND_TF"
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend"
    storage_account_name = "$storage_account_name"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
EOF
}

# Main execution flow
main() {
    if [[ "${1:-}" == "destroy" ]]; then
        initialize_backend
        destroy_backend
    else
        initialize_backend
        apply_backend
        generate_backend_tf
        log_info "Done: backend.tf created at $BACKEND_TF"
    fi
}

main "$@"
