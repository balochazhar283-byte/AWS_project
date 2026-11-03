# =============================================================================
# outputs.tf (root)
# PURPOSE: Values printed after "terraform apply" and by "terraform output".
# The database password is intentionally NOT output.
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = module.vpc.private_db_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = module.vpc.nat_gateway_id
}

output "rds_endpoint" {
  description = "RDS endpoint (host:port). Only reachable from inside the VPC."
  value       = module.rds.db_endpoint
}

output "rds_database_name" {
  description = "Name of the database."
  value       = module.rds.db_name
}

output "s3_bucket_name" {
  description = "Bucket holding monitoring reports."
  value       = module.s3.bucket_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS notification topic."
  value       = module.sns.topic_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = module.lambda.function_arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge schedule rule."
  value       = module.eventbridge.rule_name
}

output "ecr_repository_url" {
  description = "ECR repository URL used to push and pull container images."
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository."
  value       = module.ecr.repository_name
}
