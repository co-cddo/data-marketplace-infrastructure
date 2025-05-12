terraform {
  backend "s3" {
    bucket = "cddo-datamarketplace-tfstate"
    key    = "gen/terraform.tfstate"
    region = "eu-west-2"
    ##dynamodb_table = "dm-gen-dynamodb-terraform-lock-table"
    use_lockfile = true
  }
}
