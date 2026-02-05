# Backend configuration for dev environment
# Used during: terraform init -backend-config=environments/backend-dev.hcl

bucket         = "dev-terraform-state"
key            = "terraform.tfstate"
region         = "us-east-1"
encrypt        = true
