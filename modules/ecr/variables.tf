# =============================================================================
# modules/ecr/variables.tf
# PURPOSE: Inputs for the ECR (Elastic Container Registry) module. ECR is a
# private storage place for Docker/container images.
# =============================================================================

variable "project_name" {
  description = "Prefix used in the repository name and tags."
  type        = string
}

variable "repository_name" {
  description = "Short name of the repository. The final name is <project_name>-<repository_name> (lowercase)."
  type        = string
  default     = "monitoring-app"
}

variable "image_tag_mutability" {
  description = "MUTABLE = a tag such as 'latest' can be overwritten. IMMUTABLE = every tag can be pushed only once (safer for production)."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "true = AWS scans every pushed image for known vulnerabilities."
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "true = terraform destroy also deletes the repository when it still contains images (needed for a clean destroy)."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "How many tagged images to keep. Older ones are deleted automatically to save storage cost."
  type        = number
  default     = 10
}

variable "untagged_image_expiry_days" {
  description = "Delete untagged images (left behind when a tag moves to a new image) after this many days."
  type        = number
  default     = 7
}
