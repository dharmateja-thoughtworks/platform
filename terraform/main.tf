provider "aws" {
  region = var.aws_region
}

# S3 bucket for Terraform backend state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.environment}-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.environment}-terraform-state"
    Environment = var.environment
  }
}

# Enable versioning for state file protection
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

module "vpc" {
    source = "./modules/vpc"
    vpc_cidr = var.vpc_cidr
    environment = var.environment
}

module "eks" {
  source = "./modules/eks"
  env = var.environment
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}