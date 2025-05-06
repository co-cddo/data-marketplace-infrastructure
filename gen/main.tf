resource "aws_kms_key" "state_backend_bucket_kms_key" {
  description             = "Encrypt the state bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "state_backend_bucket" {
  bucket = "dm-gen-config"
}


resource "aws_s3_bucket_versioning" "state_backend_bucket_versioning" {
  bucket = aws_s3_bucket.state_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state_backend_bucket_encryption" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_backend_bucket_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# block S3 bucket public access per each Env's bucket
resource "aws_s3_bucket_public_access_block" "state_backend_bucket_acl" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



//for terraform state lock file - one table for each environment
resource "aws_dynamodb_table" "state_dynamo_table" {
  name = var.dynamodb_tablename

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


// DEVOPS ROLE

# Create an IAM policy
resource "aws_iam_policy" "devops_iam_policy" {
  name = var.devops_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create an IAM role
resource "aws_iam_role" "devops_role" {
  name = var.devops_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::855859226163:root"
        }
        Action = "sts:AssumeRole",
        Condition = {
          Bool : {
            "aws:MultiFactorAuthPresent" : "true"
          }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "devops_role_policy_attachment" {
  name       = "Policy Attachement"
  policy_arn = aws_iam_policy.devops_iam_policy.arn
  roles      = [aws_iam_role.devops_role.name]
}


// DEVELOPER ROLE

# Create an IAM policy
resource "aws_iam_policy" "developer_iam_policy" {
  name = "${var.developer_policy_name}-name"

  policy = jsonencode({

    Version : "2012-10-17",
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "logs:GetDataProtectionPolicy",
          "logs:GetLogRecord",
          "logs:GetQueryResults",
          "logs:StartQuery",
          "logs:Unmask",
          "logs:FilterLogEvents",
          "logs:GetLogGroupFields",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/docker/mygroup:*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/docker/mygroup:*"
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "logs:DescribeLogGroups",
          "logs:StartLiveTail",
          "logs:StopLiveTail",
          "logs:StopQuery",
          "logs:TestMetricFilter",
          "logs:GetLogDelivery",
          "logs:DescribeQueryDefinitions"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor3",
        "Effect" : "Allow",
        "Action" : [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/dm/docker/applications:*"
      }
    ]

  })
}

# Create an IAM role
resource "aws_iam_role" "developer_role" {
  name = var.developer_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::855859226163:root"
        }
        Action = "sts:AssumeRole",
        Condition = {
          Bool : {
            "aws:MultiFactorAuthPresent" : "true"
          }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "developer_role_policy_attachment" {
  name       = "Policy Attachement"
  policy_arn = aws_iam_policy.developer_iam_policy.arn
  roles      = [aws_iam_role.developer_role.name]
}

// READONLY ROLE

# Create an IAM role
resource "aws_iam_role" "readonly_role" {
  name = var.readonly_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::855859226163:root"
        }
        Action = "sts:AssumeRole",
        Condition = {
          Bool : {
            "aws:MultiFactorAuthPresent" : "true"
          }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "readonly_role_policy_attachment" {
  name       = "Policy Attachement"
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  roles      = [aws_iam_role.readonly_role.name]
}


resource "aws_secretsmanager_secret" "mssql_password_dev" {
  name        = var.secretmanager_mssql_masterpass_dev_name
  description = "MSSQL master password for dev"
}
resource "aws_secretsmanager_secret_version" "mssql_password_version" {
  secret_id     = aws_secretsmanager_secret.mssql_password_dev.id
  secret_string = jsonencode({
    password = "NO-PASS-HERE"
  })
}
output "secret_id" {
  value = aws_secretsmanager_secret.mssql_password_dev.id
}
