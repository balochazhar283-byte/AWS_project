# =============================================================================
# modules/iam/main.tf
# PURPOSE: Creates the Lambda "execution role" - the identity Lambda assumes
# when it runs - and gives it only the permissions it needs.
#
# Two kinds of policy are involved:
#   * Trust policy  : WHO may assume the role (the Lambda service).
#   * Permission policy: WHAT the role may do once assumed.
# =============================================================================

# Trust policy: only the Lambda service can assume this role.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "LambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = { Name = "${var.project_name}-lambda-role" }
}

# AWS-managed policy that covers two needs:
#   * CloudWatch Logs (create log stream, put log events)
#   * VPC networking (create/describe/delete the network interfaces Lambda
#     needs to live inside your private subnets)
# These ENI actions cannot be limited to specific resources, so the AWS-managed
# policy is the standard, safe choice.
resource "aws_iam_role_policy_attachment" "lambda_vpc_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_partition" "current" {}

# Custom least-privilege permissions, one statement per need.
data "aws_iam_policy_document" "lambda_permissions" {
  # Upload monitoring reports - ONLY PutObject, ONLY under reports/.
  statement {
    sid       = "UploadReportsToS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_arn}/reports/*"]
  }

  # Publish notifications - ONLY to our topic.
  statement {
    sid       = "PublishToSnsTopic"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }

  # Read the DB credentials - ONLY our secret.
  statement {
    sid       = "ReadDatabaseSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  # "RDS monitoring": read the status of OUR database instance only.
  statement {
    sid       = "DescribeDatabaseInstance"
    effect    = "Allow"
    actions   = ["rds:DescribeDBInstances"]
    resources = [var.db_instance_arn]
  }
}

resource "aws_iam_policy" "lambda_permissions" {
  name        = "${var.project_name}-lambda-permissions"
  description = "Least-privilege permissions for the database monitoring Lambda"
  policy      = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_permissions" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}
