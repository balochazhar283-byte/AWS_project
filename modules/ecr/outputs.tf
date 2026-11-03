# =============================================================================
# modules/ecr/outputs.tf
# PURPOSE: Export the repository details. The URL is what you use in
# "docker tag" / "docker push" / "docker pull" and in Lambda, ECS or EKS.
# =============================================================================

output "repository_url" {
  description = "URL used to push and pull images (<account>.dkr.ecr.<region>.amazonaws.com/<name>)."
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.main.name
}

output "registry_id" {
  description = "AWS account ID that owns the registry."
  value       = aws_ecr_repository.main.registry_id
}
