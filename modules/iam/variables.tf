# =============================================================================
# modules/iam/variables.tf
# PURPOSE: Inputs for the IAM module. Each "arn" input narrows one permission
# to ONE specific resource (least privilege).
# =============================================================================

variable "project_name" {
  description = "Prefix used in role and policy names."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the reports bucket. Lambda may only upload objects under reports/ in this bucket."
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic Lambda may publish to (from module.sns.topic_arn)."
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB credentials (from module.rds.db_secret_arn)."
  type        = string
}

variable "db_instance_arn" {
  description = "ARN of the RDS instance Lambda may describe (from module.rds.db_instance_arn)."
  type        = string
}
