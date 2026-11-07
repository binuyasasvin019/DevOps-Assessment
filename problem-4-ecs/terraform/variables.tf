variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_account_id" {
  description = "AWS account ID allowed for deployment"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Immutable Git commit SHA used as the ECR image tag"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.image_tag))
    error_message = "image_tag must be a full 40-character Git commit SHA."
  }
}