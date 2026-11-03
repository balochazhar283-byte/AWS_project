# =============================================================================
# modules/sns/main.tf
# PURPOSE: A "topic" is a mailbox others publish to; "subscriptions" are the
# people/systems that receive each message. Lambda publishes, your email
# subscribes.
#
# Permission to publish is granted to Lambda through its IAM role (module.iam),
# not here, because Lambda and the topic are in the same AWS account.
#
# EMAIL CONFIRMATION (manual, cannot be automated):
#   1. After "terraform apply", AWS emails "AWS Notification - Subscription
#      Confirmation" to alert_email (check spam too).
#   2. Click "Confirm subscription". Until then the status is
#      "PendingConfirmation" and NO monitoring emails are delivered.
#   3. Unconfirmed subscriptions are deleted by AWS after 3 days.
# =============================================================================

resource "aws_sns_topic" "monitoring" {
  name = "${var.project_name}-db-monitoring"

  tags = { Name = "${var.project_name}-db-monitoring" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
