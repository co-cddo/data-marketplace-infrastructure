terraform {
  backend "s3" {
    # BUCKET NAME SHOULD BE SET ACCORDING TO ACCOUNT TYPE
    bucket       = "dm-gen-config"
    key          = "terraform/gen/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
