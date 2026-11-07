provider "aws" {
  region = var.aws_region

  # Prevent accidental deployment to another AWS account.
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Project   = "devops-assessment"
      ManagedBy = "Terraform"
    }
  }
}
