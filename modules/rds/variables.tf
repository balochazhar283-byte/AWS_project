# =============================================================================
# modules/rds/variables.tf
# PURPOSE: Inputs for the database module. No credential has a default, so
# nothing secret is ever written in code.
# =============================================================================

variable "project_name" {
  description = "Prefix used in resource names."
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private database subnet IDs (from module.vpc). Must span two AZs."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group to attach to the database (from module.security)."
  type        = string
}

variable "db_engine" {
  description = "Database engine."
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Engine version. Use a supported MySQL version (8.4 is a current long-term release)."
  type        = string
  default     = "8.4"
}

variable "db_instance_class" {
  description = "Instance size. db.t3.micro is the smallest/cheapest."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database created inside the instance."
  type        = string
  default     = "monitordb"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password. No default: supply it with the TF_VAR_db_password environment variable."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12 && !can(regex("[/@\" ']", var.db_password))
    error_message = "Password must be at least 12 characters and must not contain / @ \" ' or spaces (RDS rules)."
  }
}

variable "db_port" {
  description = "Database port."
  type        = number
  default     = 3306
}

variable "multi_az" {
  description = "true = standby copy in another AZ (higher availability, roughly double the cost)."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "true = AWS refuses to delete the database. Set false (default) so terraform destroy works in this learning project."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to keep automated backups (1-35). 0 disables backups."
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "true = no snapshot when destroyed (clean teardown). Set false in production."
  type        = bool
  default     = true
}

variable "secret_recovery_window_in_days" {
  description = "0 = delete the secret immediately on destroy (allows re-creating with the same name). 7-30 = recoverable."
  type        = number
  default     = 0
}
