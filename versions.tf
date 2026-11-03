# =============================================================================
# versions.tf
# PURPOSE: Pins the Terraform and provider versions so the project behaves the
# same on every computer, and configures the AWS provider.
#
# Providers are plugins that teach Terraform about a platform:
#   aws     - creates AWS resources
#   archive - zips the Lambda code
#   local   - writes the Lambda source file into the build folder
# "terraform init" downloads them (they are recorded in .terraform.lock.hcl,
# which you SHOULD commit to Git).
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Credentials are NOT written here. Terraform reads them from your environment
# (aws configure, AWS_PROFILE, or AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY).
provider "aws" {
  region = var.region

  # Tags added automatically to every taggable resource.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
