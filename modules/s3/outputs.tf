# =============================================================================
# modules/s3/outputs.tf
# PURPOSE: Export the bucket name/ARN for Lambda's environment and the root
# outputs.
# =============================================================================

output "bucket_name" {
  description = "Name of the reports bucket."
  value       = aws_s3_bucket.reports.id
}

output "bucket_arn" {
  description = "ARN of the reports bucket."
  value       = aws_s3_bucket.reports.arn
}
