# =============================================================================
# main.tf (root)
# PURPOSE: The "conductor". It creates no AWS resources itself; it calls each
# module (a "module block") and passes outputs of one module into inputs of
# the next:   module.<name>.<output>
#
# HOW THE PIECES TALK AT RUN TIME
#   EventBridge --(invoke, allowed by Lambda permission)--> Lambda
#   Lambda (private app subnet, Lambda SG)
#       --> RDS API ........ via NAT -> internet -> AWS API (status)
#       --> RDS :3306 ...... inside VPC, allowed by RDS SG rule (source=Lambda SG)
#       --> Secrets Manager  via NAT (reads credentials)
#       --> S3 .............. via NAT (uploads report)
#       --> SNS ............. via NAT (publish) --> your email
#
# TERRAFORM DEPENDENCY GRAPH (arrow = "needs")
#   security -> vpc            sns -> (none)
#   rds      -> vpc, security
#   iam      -> sns, rds       (+ bucket ARN built from a local, see below)
#   s3       -> iam            (bucket policy names the Lambda role)
#   lambda   -> vpc, security, iam, rds, s3, sns
#   eventbridge -> lambda
#   ecr      -> (none)         standalone image repository
# Terraform works this out from the references, creating things in that order
# (and destroying in reverse). There is no cycle because iam does NOT use
# module.s3; it uses the bucket ARN computed from local.bucket_name.
# =============================================================================

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use your AZs if given, otherwise the first two in the region.
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  # Bucket names must be globally unique; the account ID makes it unique
  # without hardcoding it (looked up by the data source above).
  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : lower("${var.project_name}-reports-${data.aws_caller_identity.current.account_id}-${var.region}")

  # Known before anything is created -> lets IAM and S3 reference each other's
  # data without a circular dependency.
  bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}"

  lambda_function_name = "${var.project_name}-database-monitor"
}

data "aws_partition" "current" {}

# --- 1. Network ----------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = local.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# --- 2. Security groups ---------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# --- 3. SNS (before IAM, because IAM needs the topic ARN) ------------------------
module "sns" {
  source = "./modules/sns"

  project_name = var.project_name
  alert_email  = var.alert_email
}

# --- 4. RDS database + credentials secret ----------------------------------------
module "rds" {
  source = "./modules/rds"

  project_name            = var.project_name
  private_db_subnet_ids   = module.vpc.private_db_subnet_ids
  rds_security_group_id   = module.security.rds_security_group_id
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  multi_az                = var.db_multi_az
  deletion_protection     = var.db_deletion_protection
  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = var.db_skip_final_snapshot
}

# --- 5. IAM role for Lambda -------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  project_name    = var.project_name
  s3_bucket_arn   = local.bucket_arn
  sns_topic_arn   = module.sns.topic_arn
  db_secret_arn   = module.rds.db_secret_arn
  db_instance_arn = module.rds.db_instance_arn
}

# --- 6. S3 reports bucket ----------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  bucket_name     = local.bucket_name
  lambda_role_arn = module.iam.lambda_role_arn
}

# --- 7. Lambda function -------------------------------------------------------------
module "lambda" {
  source = "./modules/lambda"

  function_name          = local.lambda_function_name
  source_file            = "${path.root}/lambda_code/database_monitor.py"
  runtime                = var.lambda_runtime
  timeout                = var.lambda_timeout
  role_arn               = module.iam.lambda_role_arn
  subnet_ids             = module.vpc.private_app_subnet_ids
  security_group_ids     = [module.security.lambda_security_group_id]
  db_host                = module.rds.db_address
  db_port                = module.rds.db_port
  db_name                = module.rds.db_name
  db_instance_id         = module.rds.db_instance_id
  db_secret_arn          = module.rds.db_secret_arn
  s3_bucket_name         = module.s3.bucket_name
  sns_topic_arn          = module.sns.topic_arn
  notify_only_on_failure = var.lambda_notify_only_on_failure
  python_command         = var.python_command
}

# --- 8. EventBridge schedule ----------------------------------------------------------
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name         = var.project_name
  schedule_expression  = var.schedule_expression
  lambda_function_arn  = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
}

# --- 9. ECR container image repository -------------------------------------------------
# Standalone: nothing else depends on it, and it depends on no other module.
module "ecr" {
  source = "./modules/ecr"

  project_name         = var.project_name
  repository_name      = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  max_image_count      = var.ecr_max_image_count
}
