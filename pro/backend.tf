terraform {
  backend "s3" {
    bucket       = "dm-gen-config-prod"
    key          = "pro/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
