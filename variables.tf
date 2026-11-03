# =============================================================================
# variables.tf (root)
# PURPOSE: Every setting you can change without editing code. Values come from
# terraform.tfvars, -var flags, or TF_VAR_<name> environment variables.
# Each variable has a type, a description and (where safe) a default.
# =============================================================================

# --- General -------------------------------------------------------------------
variable "project_name" {
  description = "Short lowercase name used as a prefix for all resources."
  type        = string
  default     = "aws-monitoring"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

# --- Network ---------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Two AZs to use. Leave empty to pick the first two available in the region automatically."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets (A, B)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks of the private application subnets (A, B)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks of the private database subnets (A, B)."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

# --- Database ----------------------------------------------------------------------
variable "db_engine" {
  description = "Database engine."
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.4"
}

variable "db_instance_class" {
  description = "RDS instance size."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Database storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "monitordb"
}

variable "db_username" {
  description = "Database master username."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database master password. NO default on purpose: export TF_VAR_db_password before running Terraform."
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Create a standby database in a second AZ (about double the cost)."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Block deletion of the database. Keep false so terraform destroy works."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Days to keep automated backups."
  type        = number
  default     = 1
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (true = clean teardown)."
  type        = bool
  default     = true
}

# --- S3 ------------------------------------------------------------------------------
variable "s3_bucket_name" {
  description = "Globally unique bucket name. Leave empty to generate <project>-reports-<account-id>-<region>."
  type        = string
  default     = ""
}

# --- SNS -----------------------------------------------------------------------------
variable "alert_email" {
  description = "Email address that receives monitoring notifications (you must confirm the subscription)."
  type        = string
}

# --- Lambda --------------------------------------------------------------------------
variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 60
}

variable "lambda_notify_only_on_failure" {
  description = "true = only email when a check fails; false = email on every run."
  type        = bool
  default     = false
}

variable "python_command" {
  description = "Python command on YOUR machine used to download the MySQL driver (python3 on macOS/Linux, python on Windows)."
  type        = string
  default     = "python3"
}

# --- EventBridge ---------------------------------------------------------------------
variable "schedule_expression" {
  description = "EventBridge schedule, e.g. \"rate(5 minutes)\" or \"cron(0 8 * * ? *)\"."
  type        = string
  default     = "rate(5 minutes)"
}

# --- ECR -----------------------------------------------------------------------------
variable "ecr_repository_name" {
  description = "Short name of the ECR repository (final name: <project_name>-<this value>)."
  type        = string
  default     = "monitoring-app"
}

variable "ecr_image_tag_mutability" {
  description = "MUTABLE lets tags such as latest be overwritten; IMMUTABLE blocks that."
  type        = string
  default     = "MUTABLE"
}

variable "ecr_max_image_count" {
  description = "Number of images to keep in the repository; older ones are deleted automatically."
  type        = number
  default     = 10
}
