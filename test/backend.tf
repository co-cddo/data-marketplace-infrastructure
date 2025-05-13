terraform {
  backend "s3" {
    bucket       = "dm-gen-config"
    key          = "tst/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
