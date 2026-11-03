# =============================================================================
# terraform.tfvars
# PURPOSE: Your values for the variables in variables.tf. Terraform loads this
# file automatically.
#
# NEVER put db_password here. Provide it in your shell instead:
#   Linux/macOS : export TF_VAR_db_password='Choose-A-Strong-Pass-123'
#   PowerShell  : $env:TF_VAR_db_password = 'Choose-A-Strong-Pass-123'
# (12+ characters, no / @ " ' or spaces)
# =============================================================================

project_name = "aws-monitoring"
region       = "us-east-1"

# CHANGE THIS to a mailbox you can open, then confirm the AWS email.
alert_email = "azharhassan346890@gmail.com"

# Uncomment to change defaults:
# schedule_expression           = "rate(5 minutes)"
# lambda_notify_only_on_failure = true   # stop an email every 5 minutes
# db_multi_az                   = false
# python_command                = "python"  # Windows
