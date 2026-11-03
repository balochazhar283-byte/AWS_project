# =============================================================================
# modules/s3/main.tf
# PURPOSE: A private, encrypted, versioned bucket that stores the JSON
# monitoring reports written by Lambda.
#
# Since AWS provider v4 the bucket's settings are separate resources, each
# pointing at the bucket by its ID.
# =============================================================================

resource "aws_s3_bucket" "reports" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = { Name = var.bucket_name }
}

# Keep old versions of overwritten/deleted objects.
resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt everything at rest with S3-managed keys (AES-256).
resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# All four switches ON = the bucket can never be made public by accident.
resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Housekeeping: reports are produced every few minutes, so expire old ones.
resource "aws_s3_bucket_lifecycle_configuration" "reports" {
  bucket     = aws_s3_bucket.reports.id
  depends_on = [aws_s3_bucket_versioning.reports]

  rule {
    id     = "expire-old-reports"
    status = "Enabled"

    filter {
      prefix = "reports/"
    }

    expiration {
      days = var.report_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Bucket policy (least privilege):
#   1. Deny any request that does not use HTTPS.
#   2. Allow ONLY the Lambda role to PutObject, ONLY under reports/.
# Everyone else is denied by default (no public or cross-account access).
data "aws_iam_policy_document" "reports" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.reports.arn,
      "${aws_s3_bucket.reports.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "AllowLambdaUploadReports"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.reports.arn}/reports/*"]

    principals {
      type        = "AWS"
      identifiers = [var.lambda_role_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "reports" {
  bucket = aws_s3_bucket.reports.id
  policy = data.aws_iam_policy_document.reports.json

  # Apply the public-access block first; otherwise AWS can reject the policy
  # update while the block is still being changed.
  depends_on = [aws_s3_bucket_public_access_block.reports]
}
