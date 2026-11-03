# =============================================================================
# modules/security/variables.tf
# PURPOSE: Inputs for the security group module.
# =============================================================================

variable "project_name" {
  description = "Prefix used in resource names and tags."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups are created (from module.vpc.vpc_id)."
  type        = string
}

variable "db_port" {
  description = "Database port. MySQL uses 3306."
  type        = number
  default     = 3306
}
