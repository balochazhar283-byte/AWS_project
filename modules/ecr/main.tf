# =============================================================================
# modules/ecr/main.tf
# PURPOSE: Creates a private, encrypted container image repository with
# automatic vulnerability scanning and automatic clean-up of old images.
#
# Access: by default only principals in THIS AWS account (with IAM permission)
# can push or pull. Nothing here makes the repository public.
# =============================================================================

resource "aws_ecr_repository" "main" {
  name                 = lower("${var.project_name}-${var.repository_name}")
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  # Scan each image for known vulnerabilities when it is pushed.
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Images are encrypted at rest with an AWS-managed key.
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${var.project_name}-${var.repository_name}" }
}

# Lifecycle policy = automatic housekeeping. Rules run in priority order.
#   1. Untagged images older than N days are deleted.
#   2. Of everything else, only the newest max_image_count images are kept.
# (A rule with tagStatus "any" must have the highest priority number.)
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images after ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the newest ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}
