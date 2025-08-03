#!/bin/bash

# --- Assign global variables from command-line arguments ---

# Only the Terraform module name is accepted as a parameter
MODULE="$1"
TFVARS_FILE="credentials.tfvars"
TFPLAN_FILE="${MODULE}.tfplan"
temp_output_file=$(mktemp)

# --- Function to extract variables from the tfvars file ---
function extract_tfvars() {
    # Helper function to read a variable value from the tfvars file
    # Arguments: variable name
    # Output: variable value or empty string
    grep -E "^$1\s*=" "$TFVARS_FILE" | sed -E "s/^$1\s*=\s*\"(.*)\"/\1/"
}

# --- Read Azure credential variables from credentials.tfvars ---

# Extract subscription_id, client_id, client_secret, tenant_id from tfvars file
ARM_SUBSCRIPTION_ID=$(extract_tfvars subscription_id)
ARM_CLIENT_ID=$(extract_tfvars client_id)
ARM_CLIENT_SECRET=$(extract_tfvars client_secret)
ARM_TENANT_ID=$(extract_tfvars tenant_id)

# --- Validate required inputs before proceeding ---

if [ -z "${MODULE}" ]; then
    echo "Error: Missing required argument MODULE."
    echo "Usage: $0 <MODULE>"
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

# --- Functions ---

function run_terraform_plan() {
    echo "=== Running terraform plan ==="
    terraform plan -var-file="$TFVARS_FILE" -target="module.${MODULE}" -out="$TFPLAN_FILE"
}

function run_terraform_apply() {
    echo "=== Attempting to apply Terraform plan for module: ${MODULE} ==="
    terraform apply -var-file="$TFVARS_FILE" -auto-approve "$TFPLAN_FILE" 2>&1 | tee "$temp_output_file" || true
}

function import_resource_group_if_needed() {
    # Import the resource group once per run, if needed
    if [ "$RG_IMPORTED" != "true" ]; then
        echo "=== Importing module.${MODULE}.azurerm_resource_group.app_grp ==="
        terraform import -var-file="$TFVARS_FILE" -input=false "module.${MODULE}.azurerm_resource_group.app_grp" "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/rg-${MODULE}" || true
        RG_IMPORTED="true"
    else
        echo "=== Resource group import already attempted, skipping import. ==="
    fi
}

function extract_and_import() {
    echo "=== Terraform apply failed, attempting to import existing resources. ==="

    # Parse error output for resource IDs and names, then import those resources into state
    grep -E 'Error:|with module' "$temp_output_file" | paste - - | while IFS=$'\t' read -r error_line with_line; do
        ID=$(echo "$error_line" | sed -n 's/.*ID "\(\/subscriptions[^"]*\)".*/\1/p')
        RESNAME=$(echo "$with_line" | sed -n 's/.*with \(module\.[^,]*\),.*/\1/p')
        if [[ -n "$ID" && -n "$RESNAME" ]]; then
            echo "=== Importing resource: ${RESNAME} with ID: ${ID} ==="
            terraform import -var-file="$TFVARS_FILE" -input=false "${RESNAME}" "${ID}"
        fi
    done

    echo "=== Imports completed. Retrying apply... ==="
}

# --- Main execution loop ---

function main() {
    RG_IMPORTED="false"  # Flag to ensure resource group import only happens once

    while true; do
        run_terraform_plan
        run_terraform_apply

        apply_output=$(cat "$temp_output_file")

        # Check if apply succeeded by absence of "Error" keyword
        if ! echo "$apply_output" | grep -q "Error"; then
            echo "=== Terraform apply completed successfully. ==="
            break
        fi

        # If failure due to existing resources, import and retry
        if echo "$apply_output" | grep -q "already exists"; then
            import_resource_group_if_needed
            extract_and_import
            continue
        else
            # Unrecoverable error – print output and exit
            echo "=== Terraform apply failed with a non-recoverable error. ==="
            echo "$apply_output"
            rm -f "$temp_output_file"
            exit 1
        fi
    done

    rm -f "$temp_output_file"
}

# --- Start script ---
main
