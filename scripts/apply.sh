#!/bin/bash

# A function to handle errors
set -e

# Define variables
MODULE="$1"
ARM_SUBSCRIPTION_ID="$2"
TFVARS_FILE="credentials.tfvars"
TFPLAN_FILE="${MODULE}.tfplan"
temp_output_file=$(mktemp)

# --- Functions ---

# Function to run terraform plan
function run_terraform_plan() {
  echo "=== Running terraform plan ==="
  terraform plan -var-file="$TFVARS_FILE" -target="module.${MODULE}" -out="$TFPLAN_FILE"
}

# Function to run terraform apply and capture output
function run_terraform_apply() {
  echo "=== Attempting to apply Terraform plan ==="
  terraform apply -var-file="$TFVARS_FILE" -auto-approve "$TFPLAN_FILE" 2>&1 | tee "$temp_output_file" || true
}

# Function to extract resource IDs and names from apply errors and run imports
function extract_and_import() {
  echo "=== Terraform apply failed, attempting to import existing resources. ==="
  
  # The following logic extracts the resource ID and name from the error messages
  # and runs `terraform import` for each of them.
  grep -E 'Error:|with module' "$temp_output_file" | paste - - | while IFS=$'\t' read -r error_line with_line; do
      ID=$(echo "$error_line" | sed -n 's/.*ID "\(\/subscriptions[^"]*\)".*/\1/p')
      RESNAME=$(echo "$with_line" | sed -n 's/.*with \(module\.[^,]*\),.*/\1/p')
      echo "=== Importing resource: ${RESNAME} with ID: ${ID} ==="
      terraform import -var-file="$TFVARS_FILE" -input=false "${RESNAME}" "${ID}"
  done
  
  echo "=== Imports completed. Retrying apply... ==="
}

# Main function to handle the entire import and apply workflow
function main() {
  echo "=== Attempting to apply Terraform plan for module: ${MODULE} ==="
  
  # Initial import of the resource group, which is a common failure point
  echo "=== Importing module.${MODULE}.azurerm_resource_group.app_grp ==="
  terraform import -var-file="$TFVARS_FILE" -input=false "module.${MODULE}.azurerm_resource_group.app_grp" "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/rg-${MODULE}" || true
  
  # Loop indefinitely until a successful apply or a non-recoverable error occurs
  while true; do
      run_terraform_plan
      run_terraform_apply
      
      apply_output=$(cat "$temp_output_file")
      
      # Check if the apply was successful by looking for the absence of "Error"
      if ! echo "$apply_output" | grep -q "Error"; then
          echo "=== Terraform apply completed successfully. ==="
          break
      fi
      
      # If apply failed, check for the specific "already exists" error
      if echo "$apply_output" | grep -q "already exists"; then
          extract_and_import
          continue # Continue the loop to try the apply again
      else
          # Handle non-recoverable errors
          echo "=== Terraform apply failed with a non-recoverable error. ==="
          echo "${apply_output}"
          exit 1
      fi
  done
  
  # Clean up the temporary file
  rm "$temp_output_file"
}

# --- Main script execution ---
main