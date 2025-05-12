terraform {
  backend "s3" {
    bucket       = "cddo-datamarketplace-tfstate"
    key          = "gen/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
