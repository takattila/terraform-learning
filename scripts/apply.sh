#!/bin/bash

# This script automates applying a Terraform module by:
# - Extracting Azure credentials from 'credentials.tfvars'
# - Running 'terraform plan' for the specified module
# - Running 'terraform apply' and capturing output
# - On 'resource already exists' errors, importing existing resources and retrying apply
# - Importing the Azure resource group once if needed
# - Validating required inputs before running
# - Looping until successful apply or unrecoverable error occurs

# Usage example:
# ./apply.sh <MODULE> <ENV>
# Example: ./apply.sh app_module dev

# --- Global variables from command-line arguments ---
# The Terraform module name and environment are accepted as parameters
MODULE="$1"
ENVIRONMENT="$2"
TFVARS_FILE="credentials.tfvars"
TFPLAN_FILE="${MODULE}.tfplan"
temp_output_file=$(mktemp)

# --- Helper function to extract variables from tfvars file ---
function extract_tfvars() {
    # Arguments: variable name
    # Returns: value of the variable from the tfvars file, or empty string if not found
    grep -E "^$1\s*=" "$TFVARS_FILE" | sed -E "s/^$1\s*=\s*\"(.*)\"/\1/"
}

# Function to configure Azure credentials in a .tfvars file
function configure_credentials() {
    if [[ -z "$ARM_SUBSCRIPTION_ID" || -z "$ARM_CLIENT_ID" || -z "$ARM_CLIENT_SECRET" || -z "$ARM_TENANT_ID" ]]; then
        echo "=== Configuring credentials in ${TFVARS_FILE} ==="
        
        # Create the credentials file
        echo 'subscription_id = "'"${ARM_SUBSCRIPTION_ID}"'"' > "$TFVARS_FILE"
        echo 'client_id       = "'"${ARM_CLIENT_ID}"'"' >> "$TFVARS_FILE"
        echo 'client_secret   = "'"${ARM_CLIENT_SECRET}"'"' >> "$TFVARS_FILE"
        echo 'tenant_id       = "'"${ARM_TENANT_ID}"'"' >> "$TFVARS_FILE"
    fi
}

# --- Function to extract Azure credentials and validate required inputs ---
function validate_inputs() {
    # Extract Azure credentials from the tfvars file
    ARM_SUBSCRIPTION_ID=$(extract_tfvars subscription_id)
    ARM_CLIENT_ID=$(extract_tfvars client_id)
    ARM_CLIENT_SECRET=$(extract_tfvars client_secret)
    ARM_TENANT_ID=$(extract_tfvars tenant_id)
    
    # Validate required arguments and files
    if [ -z "${MODULE}" ] || [ -z "${ENVIRONMENT}" ]; then
        echo "Error: Missing required arguments MODULE and ENV."
        echo "Usage: $0 <MODULE> <ENV>"
        echo "Example: $0 app_module dev"
        exit 1
    fi
    
    if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "qa" && "$ENVIRONMENT" != "prod" ]]; then
        echo "Error: ENV must be one of: dev, qa, prod"
        exit 1
    fi
    
    if [ ! -f "$TFVARS_FILE" ]; then
        echo "Error: Terraform variables file '$TFVARS_FILE' not found."
        exit 1
    fi
    
    if [ -z "${ARM_SUBSCRIPTION_ID}" ] || [ -z "${ARM_CLIENT_ID}" ] || [ -z "${ARM_CLIENT_SECRET}" ] || [ -z "${ARM_TENANT_ID}" ]; then
        echo "Error: One or more required Azure credentials are missing in $TFVARS_FILE."
        echo "Please ensure subscription_id, client_id, client_secret, and tenant_id are set."
        exit 1
    fi
}

# --- Runs terraform plan command ---
function run_terraform_plan() {
    echo "=== Running terraform plan ==="
    terraform plan \
    -var-file="$TFVARS_FILE" \
    -var="env=${ENVIRONMENT}" \
    -target="module.${MODULE}" \
    -out="$TFPLAN_FILE"
}

# --- Runs terraform apply command and logs output ---
function run_terraform_apply() {
    echo "=== Attempting to apply Terraform plan for module: ${MODULE} ==="
    terraform apply \
    -var-file="$TFVARS_FILE" \
    -var="env=${ENVIRONMENT}" \
    -auto-approve "$TFPLAN_FILE" 2>&1 | tee "$temp_output_file" || true
}

# --- Import resource group once if needed ---
function import_resource_group_if_needed() {
    if [ "$RG_IMPORTED" != "true" ]; then
        echo "=== Importing module.${MODULE}.azurerm_resource_group.app_grp ==="
        terraform import \
        -var-file="$TFVARS_FILE" \
        -var="env=${ENVIRONMENT}" \
        -input=false \
        "module.${MODULE}.azurerm_resource_group.app_grp" \
        "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/rg-${MODULE}-${ENVIRONMENT}" || true
        RG_IMPORTED="true"
    else
        echo "=== Resource group import already attempted, skipping import. ==="
    fi
}

# --- Extract resources from error output and import them ---
function extract_and_import() {
    echo "=== Terraform apply failed, attempting to import existing resources. ==="
    
    grep -E 'Error:|with module' "$temp_output_file" | paste - - | while IFS=$'\t' read -r error_line with_line; do
        ID=$(echo "$error_line" | sed -n 's/.*ID "\(\/subscriptions[^"]*\)".*/\1/p')
        RESNAME=$(echo "$with_line" | sed -n 's/.*with \(module\.[^,]*\),.*/\1/p')
        if [[ -n "$ID" && -n "$RESNAME" ]]; then
            echo "=== Importing resource: ${RESNAME} with ID: ${ID} ==="
            terraform import \
            -var-file="$TFVARS_FILE" \
            -var="env=${ENVIRONMENT}" \
            -input=false "${RESNAME}" "${ID}"
        fi
    done
    
    echo "=== Imports completed. Retrying apply... ==="
}

# --- Function to clean up temporary files and credentials ---
function cleanup() {
    rm -f "$TFVARS_FILE"
}

# --- Main execution loop ---
function main() {
    configure_credentials
    validate_inputs
    
    RG_IMPORTED="false"  # Flag to ensure resource group import only happens once
    
    while true; do
        run_terraform_plan
        run_terraform_apply
        
        apply_output=$(cat "$temp_output_file")
        
        # Check if apply succeeded by absence of "Error"
        if ! echo "$apply_output" | grep -q "Error"; then
            echo "=== Terraform apply completed successfully. ==="
            break
        fi
        
        # If failure due to existing resources, attempt import and retry
        if echo "$apply_output" | grep -q "already exists"; then
            import_resource_group_if_needed
            extract_and_import
            continue
        else
            # Unrecoverable error – print output and exit
            echo "=== Terraform apply failed with a non-recoverable error. ==="
            echo "$apply_output"
            cleanup
            exit 1
        fi
    done
    
    cleanup
}

# --- Start script ---
main "$@"
