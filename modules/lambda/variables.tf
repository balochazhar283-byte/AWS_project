# =============================================================================
# modules/lambda/variables.tf
# PURPOSE: Inputs for the Lambda module.
# =============================================================================

variable "function_name" {
  description = "Name of the Lambda function (also names its CloudWatch log group)."
  type        = string
}

variable "source_file" {
  description = "Path to the Python source file (root passes lambda_code/database_monitor.py)."
  type        = string
}

variable "handler" {
  description = "Entry point: <file name without .py>.<function name>."
  type        = string
  default     = "database_monitor.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Maximum run time in seconds (3-900)."
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Memory in MB (CPU scales with it)."
  type        = number
  default     = 256
}

variable "role_arn" {
  description = "IAM execution role ARN (from module.iam)."
  type        = string
}

variable "subnet_ids" {
  description = "Private application subnet IDs (from module.vpc)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the function (from module.security)."
  type        = list(string)
}

variable "db_host" {
  description = "RDS hostname (from module.rds)."
  type        = string
}

variable "db_port" {
  description = "RDS port (from module.rds)."
  type        = number
}

variable "db_name" {
  description = "Database name (from module.rds)."
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance identifier (from module.rds)."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN holding DB credentials (from module.rds)."
  type        = string
}

variable "s3_bucket_name" {
  description = "Bucket that receives reports (from module.s3)."
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic to notify (from module.sns)."
  type        = string
}

variable "notify_only_on_failure" {
  description = "true = email only when something is wrong. false = email on every run (every 5 minutes by default)."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Days CloudWatch keeps the function logs."
  type        = number
  default     = 14
}

variable "pymysql_version" {
  description = "Version of the pure-Python MySQL driver bundled into the deployment package."
  type        = string
  default     = "1.1.1"
}

variable "python_command" {
  description = "Command used at plan/apply time to run pip on YOUR computer (use \"python\" on Windows)."
  type        = string
  default     = "python3"
}
