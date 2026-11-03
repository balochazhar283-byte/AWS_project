# =============================================================================
# modules/eventbridge/main.tf
# PURPOSE: A cron-like scheduler. Three pieces are required:
#   1. Rule       - "fire on this schedule"
#   2. Target     - "when it fires, call this Lambda"
#   3. Permission - Lambda's own resource policy that says EventBridge may call it
# Missing the permission is the #1 reason scheduled Lambdas silently never run.
# =============================================================================

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.project_name}-db-monitor-schedule"
  description         = "Invokes the database monitoring Lambda on a schedule"
  schedule_expression = var.schedule_expression
  state               = "ENABLED"

  tags = { Name = "${var.project_name}-db-monitor-schedule" }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "invoke-database-monitor"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn # only THIS rule may invoke
}
