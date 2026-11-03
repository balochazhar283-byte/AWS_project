# =============================================================================
# modules/sns/variables.tf
# PURPOSE: Inputs for the notification module.
# =============================================================================

variable "project_name" {
  description = "Prefix used in the topic name."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives monitoring notifications. AWS sends it a confirmation email that you MUST click."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}
