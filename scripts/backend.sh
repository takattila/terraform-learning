#!/bin/bash
set -euo pipefail

# This script manages the Terraform backend infrastructure by:
# - Initializing the backend module
# - Applying or destroying the backend resources
# - Generating backend.tf in env/${env}/ with the correct storage account
# - Accepting an environment parameter (env = dev, qa, prod)

# Usage:
# ./backend.sh dev
# ./backend.sh destroy         # destroys all environments
# ./backend.sh destroy qa      # destroys only qa

# --- Define paths ---
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/infra/backend"
TFVARS_FILE="$ROOT_DIR/credentials.tfvars"

# --- Logging helpers ---
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# --- Exit with error message ---
exit_with_error() {
    log_error "$1"
    exit 1
}

# --- Initialize Terraform backend module ---
initialize_backend() {
    log_info "Initializing Terraform backend module..."
    terraform -chdir="$BACKEND_DIR" init -upgrade
}

# --- Apply backend infrastructure ---
apply_backend() {
    log_info "Applying backend infrastructure..."
    if [ ! -f "$TFVARS_FILE" ]; then
        exit_with_error "Missing credentials file: $TFVARS_FILE"
    fi
    terraform -chdir="$BACKEND_DIR" apply -var-file="$TFVARS_FILE" -var="env=${ENVIRONMENT}" -auto-approve
}

# --- Destroy backend infrastructure ---
destroy_backend() {
    log_info "Destroying backend infrastructure..."
    if [ ! -f "$TFVARS_FILE" ]; then
        exit_with_error "Missing credentials file: $TFVARS_FILE"
    fi
    
    # env is optional for destroy, so we don't pass it
    terraform -chdir="$BACKEND_DIR" destroy -var-file="$TFVARS_FILE" -auto-approve || exit_with_error "Terraform destroy failed"
    
    if [[ -n "${ENVIRONMENT:-}" ]]; then
        backend_tf_path="$ROOT_DIR/env/${ENVIRONMENT}/backend.tf"
        if [ -f "$backend_tf_path" ]; then
            log_info "Removing $backend_tf_path..."
            rm -f "$backend_tf_path"
        fi
        log_info "Backend.tf removed for env: $ENVIRONMENT"
    else
        for env in dev qa prod; do
            backend_tf_path="$ROOT_DIR/env/${env}/backend.tf"
            if [ -f "$backend_tf_path" ]; then
                log_info "Removing $backend_tf_path for $env..."
                rm -f "$backend_tf_path"
            fi
        done
        log_info "All backend.tf files removed."
    fi
}

# --- Retrieve storage account name from Terraform output ---
get_storage_account_name() {
    terraform -chdir="$BACKEND_DIR" output -raw storage_account_name || exit_with_error "Output 'storage_account_name' is empty or unavailable."
}

# --- Generate backend.tf file in env/${env}/ ---
generate_backend_tf() {
    local storage_account_name
    local backend_tf_path="$ROOT_DIR/env/${ENVIRONMENT}/backend.tf"
    
    log_info "Retrieving storage account name..."
    storage_account_name=$(get_storage_account_name)
    
    log_info "Generating backend.tf at $backend_tf_path with storage account: $storage_account_name and env: $ENVIRONMENT"
    mkdir -p "$(dirname "$backend_tf_path")"
    
    cat <<EOF > "$backend_tf_path"
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend"
    storage_account_name = "$storage_account_name"
    container_name       = "tfstate"
    key                  = "${ENVIRONMENT}-terraform.tfstate"
  }
}
EOF
}

# --- Main execution flow ---
main() {
    ACTION=""
    ENVIRONMENT=""
    
    if [[ "${1:-}" == "destroy" ]]; then
        ACTION="destroy"
        ENVIRONMENT="${2:-}"
    else
        ACTION="apply"
        ENVIRONMENT="${1:-}"
    fi
    
    if [[ "$ACTION" == "apply" && -z "$ENVIRONMENT" ]]; then
        exit_with_error "Missing environment argument. Usage: $0 <env>"
    fi
    
    if [[ -n "$ENVIRONMENT" && "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "qa" && "$ENVIRONMENT" != "prod" ]]; then
        exit_with_error "Invalid environment: $ENVIRONMENT. Must be one of: dev, qa, prod"
    fi
    
    initialize_backend
    
    if [[ "$ACTION" == "destroy" ]]; then
        destroy_backend
    else
        apply_backend
        generate_backend_tf
        log_info "Done: backend.tf created at env/${ENVIRONMENT}/backend.tf"
    fi
}

main "$@"
