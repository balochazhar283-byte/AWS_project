# =============================================================================
# modules/security/outputs.tf
# PURPOSE: Export the security group IDs so the RDS module (attach the RDS
# group) and the Lambda module (attach the Lambda group) can use them.
# =============================================================================

output "lambda_security_group_id" {
  description = "ID of the security group for the Lambda function."
  value       = aws_security_group.lambda.id
}

output "rds_security_group_id" {
  description = "ID of the security group for the RDS database."
  value       = aws_security_group.rds.id
}
