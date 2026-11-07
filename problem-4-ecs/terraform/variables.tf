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
variable "cloudfront_origin_secret" {
  description = "Secret header value used to authenticate CloudFront requests at the ALB"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.cloudfront_origin_secret) >= 32
    error_message = "The CloudFront origin secret must be at least 32 characters."
  }
}