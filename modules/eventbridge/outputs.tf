# =============================================================================
# modules/eventbridge/outputs.tf
# PURPOSE: Export the rule identifiers.
# =============================================================================

output "rule_name" {
  description = "Name of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.schedule.name
}

output "rule_arn" {
  description = "ARN of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.schedule.arn
}
