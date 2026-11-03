# =============================================================================
# modules/iam/outputs.tf
# PURPOSE: Export the role so the Lambda module can run as it and the S3
# module can name it in the bucket policy.
# =============================================================================

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role."
  value       = aws_iam_role.lambda.name
}
