terraform {
  backend "s3" {
    bucket         = "dm-gen-config"
    key            = "stg/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "dm-gen-dynamodb-terraform-lock-table"
  }
}
