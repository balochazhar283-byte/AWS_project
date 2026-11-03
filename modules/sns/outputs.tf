# =============================================================================
# modules/sns/outputs.tf
# PURPOSE: Export the topic ARN (its unique ID) for IAM and Lambda.
# =============================================================================

output "topic_arn" {
  description = "ARN of the monitoring SNS topic."
  value       = aws_sns_topic.monitoring.arn
}

output "topic_name" {
  description = "Name of the monitoring SNS topic."
  value       = aws_sns_topic.monitoring.name
}
