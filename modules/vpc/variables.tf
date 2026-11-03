# =============================================================================
# modules/vpc/variables.tf
# PURPOSE: Declares the INPUTS of the VPC module. A module is like a function:
# variables are its parameters, resources are its body, outputs are its return
# values. The root module passes these values in from main.tf.
# =============================================================================

variable "project_name" {
  description = "Short name used as a prefix in the Name tag of every resource."
  type        = string
}

variable "vpc_cidr" {
  description = "IP range of the whole VPC (a private network inside AWS)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Two Availability Zones (separate data centres) to spread subnets across, e.g. [\"us-east-1a\", \"us-east-1b\"]."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least two Availability Zones (RDS subnet groups require two)."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ). They hold the NAT Gateway."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets (one per AZ). The Lambda function runs here."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for the private database subnets (one per AZ). The RDS database runs here."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}
