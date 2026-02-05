#!/bin/bash

# ==============================================================================
# Terraform Management Script
# Usage: ./manage.sh <environment> <action> <var-file>
# Example: ./manage.sh dev plan dev.tfvars
# ==============================================================================

# 1. Read Arguments
ENV=$1
VAR_FILE=$2
ACTION=$3

# 2. Validation: Check if arguments are provided
if [ -z "$ENV" ] || [ -z "$VAR_FILE" ] || [ -z "$ACTION" ]; then
  echo "❌ Error: Missing arguments."
  echo "Usage: ./manage.sh <environment> <var-file> <action>"
  echo "Valid Actions: init, plan, apply, destroy"
  echo "Example: ./manage.sh dev plan dev.tfvars"
  exit 1
fi

if ! [[ "$ACTION" =~ ^(init|plan|apply|destroy)$ ]]; then
  echo "❌ Error: Invalid action."
  echo "Usage: ./manage.sh <environment> <var-file> <action>"
  echo "Valid Actions: init, plan, apply, destroy"
  echo "Example: ./manage.sh dev plan dev.tfvars"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_ROOT="$SCRIPT_DIR/.."
ENV_DIR="$TF_ROOT/environments"

VAR_FILE_PATH="$ENV_DIR/$VAR_FILE"

cd "$TF_ROOT"


# Removed validation for var file name.
# This allows any string to be passed as the variable file,
# which may lead to unexpected behavior or errors in Terraform.
VAR_FILE=$2

# Only allow 'dev' or 'prod' as environment
if ! [[ "$ENV" =~ ^(dev|prod)$ ]]; then
  echo "❌ Error: Invalid environment."
  echo "Usage: ./manage.sh <environment> <var-file> <action>"
  echo "Valid Environments: dev, prod"
  echo "Example: ./manage.sh dev plan dev.tfvars"
  exit 1
fi

# 3. Validation: Check if environment directory exists
if [ ! -f "$VAR_FILE_PATH" ]; then
  echo "❌ Error: Var file '$VAR_FILE' not found."
  exit 1
fi

# 4. Execute Terraform Commands
if [ "$ACTION" == "init" ]; then
    # Init doesn't use var-files or state paths usually, it downloads plugins
    terraform init -backend-config="state.config" -upgrade

elif [ "$ACTION" == "plan" ]; then
    terraform plan \
      -var-file="$VAR_FILE_PATH"

elif [ "$ACTION" == "apply" ]; then
    terraform apply \
      -var-file="$VAR_FILE_PATH" \
      -auto-approve

elif [ "$ACTION" == "destroy" ]; then
    terraform destroy \
      -var-file="$VAR_FILE_PATH" \
      -auto-approve

else
    echo "❌ Error: Invalid action '$ACTION'. Use init, plan, apply, or destroy."
    exit 1
fi