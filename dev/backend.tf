terraform {
  backend "s3" {
    bucket       = "dm-gen-config"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
