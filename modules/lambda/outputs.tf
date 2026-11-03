# =============================================================================
# modules/lambda/outputs.tf
# PURPOSE: Export what EventBridge needs to invoke the function, plus values
# for the root outputs.
# =============================================================================

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.monitor.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.monitor.arn
}

output "log_group_name" {
  description = "CloudWatch log group of the function."
  value       = aws_cloudwatch_log_group.lambda.name
}
