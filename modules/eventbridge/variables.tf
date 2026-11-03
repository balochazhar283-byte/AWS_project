# =============================================================================
# modules/eventbridge/variables.tf
# PURPOSE: Inputs for the scheduler module.
# =============================================================================

variable "project_name" {
  description = "Prefix used in the rule name."
  type        = string
}

variable "schedule_expression" {
  description = "How often to run. Examples: \"rate(5 minutes)\", \"rate(1 hour)\", \"cron(0 8 * * ? *)\" (08:00 UTC daily)."
  type        = string
  default     = "rate(5 minutes)"
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke (from module.lambda)."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function (needed for the invoke permission)."
  type        = string
}
