# =============================================================================
# modules/rds/main.tf
# PURPOSE: Creates a private, encrypted MySQL database and stores its
# connection details in AWS Secrets Manager for the Lambda function.
# =============================================================================

# A DB subnet group tells RDS which subnets it may use. We give it only the
# private DB subnets, so the database can never land in a public subnet.
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Private database subnets"
  subnet_ids  = var.private_db_subnet_ids

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-mysql"
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true # encryption at rest (AWS-managed KMS key)

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false # never reachable from the internet

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection

  auto_minor_version_upgrade = true
  apply_immediately          = true

  # Safe, repeatable destroy: skip the final snapshot (configurable).
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-mysql-final"

  tags = { Name = "${var.project_name}-mysql" }
}

# --- Credentials for Lambda, kept in Secrets Manager (not in env variables) ----
# Lambda receives only the secret's ARN and reads the content at run time.
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}/db-credentials"
  description             = "Connection details for the monitored RDS MySQL database"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = { Name = "${var.project_name}-db-credentials" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}
