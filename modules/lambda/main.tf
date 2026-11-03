# =============================================================================
# modules/lambda/main.tf
# PURPOSE: Packages lambda_code/database_monitor.py (plus the pymysql driver),
# creates the function inside the private app subnets and a log group.
#
# PACKAGING FLOW (all on your own computer, before upload):
#   1. terraform_data.install_dependencies : pip installs pymysql into .build/
#   2. local_file.handler                  : copies database_monitor.py there
#   3. data.archive_file.package           : zips the .build folder
#   4. aws_lambda_function                 : uploads the zip
# pymysql is pure Python, so a zip built on Windows/macOS/Linux works on Lambda.
# =============================================================================

locals {
  build_dir = "${path.root}/.build/${var.function_name}"
  zip_path  = "${path.root}/.build/${var.function_name}.zip"
}

# Step 1: install the MySQL driver next to the code. Re-runs only if the
# pinned version changes. (If you delete .build/, run
#   terraform apply -replace=module.lambda.terraform_data.install_dependencies )
resource "terraform_data" "install_dependencies" {
  triggers_replace = [var.pymysql_version]

  provisioner "local-exec" {
    command = "${var.python_command} -m pip install --quiet --upgrade --target \"${local.build_dir}\" pymysql==${var.pymysql_version}"
  }
}

# Step 2: copy our code into the same folder (works on every OS).
resource "local_file" "handler" {
  content  = file(var.source_file)
  filename = "${local.build_dir}/${basename(var.source_file)}"
}

# Step 3: zip the folder. depends_on guarantees steps 1 and 2 finish first.
data "archive_file" "package" {
  type        = "zip"
  source_dir  = local.build_dir
  output_path = local.zip_path

  depends_on = [terraform_data.install_dependencies, local_file.handler]
}

# Create the log group ourselves so it has a retention period and is removed on
# terraform destroy (otherwise Lambda creates one that lives forever).
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.function_name}-logs" }
}

resource "aws_lambda_function" "monitor" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = data.archive_file.package.output_path
  source_code_hash = data.archive_file.package.output_base64sha256

  # Run inside the private app subnets with the Lambda security group.
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  # Only NON-secret settings. The password is fetched from Secrets Manager.
  environment {
    variables = {
      DB_HOST                = var.db_host
      DB_PORT                = tostring(var.db_port)
      DB_NAME                = var.db_name
      DB_INSTANCE_ID         = var.db_instance_id
      DB_SECRET_ARN          = var.db_secret_arn
      REPORT_BUCKET          = var.s3_bucket_name
      SNS_TOPIC_ARN          = var.sns_topic_arn
      NOTIFY_ONLY_ON_FAILURE = tostring(var.notify_only_on_failure)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = { Name = var.function_name }
}
