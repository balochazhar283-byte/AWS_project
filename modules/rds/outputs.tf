# =============================================================================
# modules/rds/outputs.tf
# PURPOSE: Export connection information (never the password).
# =============================================================================

output "db_endpoint" {
  description = "Connection endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "Hostname of the database."
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port of the database."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.main.db_name
}

output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.main.identifier
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret with the DB credentials (the ARN is not secret; the content is)."
  value       = aws_secretsmanager_secret.db.arn
}
