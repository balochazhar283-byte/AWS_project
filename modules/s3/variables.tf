# =============================================================================
# modules/s3/variables.tf
# PURPOSE: Inputs for the reports bucket module.
# =============================================================================

variable "bucket_name" {
  description = "Globally unique bucket name (S3 names are shared by all AWS accounts worldwide)."
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role that is allowed to upload reports (from module.iam)."
  type        = string
}

variable "force_destroy" {
  description = "true = terraform destroy also deletes the objects (needed because reports accumulate)."
  type        = bool
  default     = true
}

variable "report_expiration_days" {
  description = "Delete reports older than this many days (keeps storage cost near zero)."
  type        = number
  default     = 30
}
