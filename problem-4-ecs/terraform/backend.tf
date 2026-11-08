terraform {
  backend "s3" {
    key          = "problem-4-ecs/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}