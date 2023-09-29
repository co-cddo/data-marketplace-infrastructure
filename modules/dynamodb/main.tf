//for terraform state lock file - one table for each environment
resource "aws_dynamodb_table" "state_dynamo_table" {
  name = "tf-state-lock-${var.env_name}"

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}