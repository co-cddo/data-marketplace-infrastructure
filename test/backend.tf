terraform {

   backend "s3" {
      bucket = "dm-gen-configuration"
      key = "test/terraform.tfstate"
      region = "eu-west-3"
    }  
}