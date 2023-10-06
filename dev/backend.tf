terraform {
   backend "s3" {
      bucket = "dm-gen-configuration"
      key = "dev/terraform.tfstate"
      region = "eu-north-1"
      dynamodb_table = "dm-gen-dynamodb-terraform-lock-table"
    }  
}
