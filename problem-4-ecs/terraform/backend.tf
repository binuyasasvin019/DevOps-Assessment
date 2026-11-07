terraform {
  backend "s3" {
    bucket       = "devops-assessment-tfstate-968758165441-ap-southeast-2"
    key          = "problem-4-ecs/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}