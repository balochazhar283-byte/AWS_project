# =============================================================================
# modules/security/main.tf
# PURPOSE: Security groups are stateful virtual firewalls attached to network
# interfaces. Here we make a "Lambda" group and an "RDS" group, and allow
# ONLY the Lambda group to reach the database port.
#
# Referencing a security group instead of an IP address means: "anything that
# wears the Lambda badge may connect". Lambda's IPs change; the badge does not.
# =============================================================================

resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-"
  description = "Security group for the database monitoring Lambda function"
  vpc_id      = var.vpc_id

  # Lets Terraform replace the group safely if a change forces re-creation.
  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-lambda-sg" }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  description = "Security group for the RDS MySQL database"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# Lambda -> outside world. Lambda must reach: RDS (inside VPC), and AWS APIs
# (S3, SNS, Secrets Manager, RDS API) through the NAT Gateway over HTTPS.
resource "aws_vpc_security_group_egress_rule" "lambda_all_out" {
  security_group_id = aws_security_group.lambda.id
  description       = "Allow all outbound (DB traffic and HTTPS to AWS APIs via NAT)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# World -> RDS: NOT allowed. The only inbound rule accepts MySQL traffic whose
# source is the Lambda security group. No 0.0.0.0/0 anywhere on the database.
resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from the Lambda security group only"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.lambda.id
}
