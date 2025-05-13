data "aws_caller_identity" "current" {}

resource "aws_kms_key" "state_backend_bucket_kms_key" {
  description             = "Encrypt the state bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "state_backend_bucket" {
  bucket = "dm-gen-config-prod"
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



resource "aws_iam_role" "adm_ec2_profile_role" {
  name = var.adm_ec2_profile_role_name

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.adm_ec2_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.adm_ec2_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "adm-ec2-instance-profile"
  role = aws_iam_role.adm_ec2_profile_role.name
}

resource "aws_iam_role" "devops_role" {
  name = var.devops_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
        "Resource" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/tmp/docker/mygroup:*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/tmp/docker/mygroup:*"
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
        "Resource" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/tmp/dm/docker/applications:*"
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
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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


resource "aws_secretsmanager_secret" "mssql_passwords" {
  name        = "dm-gen-mssql-master-credentials"
  description = "MSSQL master credentials"
}
resource "aws_secretsmanager_secret_version" "mssql_passwords_version" {
  secret_id = aws_secretsmanager_secret.mssql_passwords.id
  secret_string = jsonencode({
    dbusername   = "saadmin",
    dev-password = "NO-PASS-HERE",
    tst-password = "NO-PASS-HERE",
    stg-password = "NO-PASS-HERE",
    pro-password = "NO-PASS-HERE"
  })
}

resource "aws_secretsmanager_secret" "postgresql_passwords" {
  name        = "dm-gen-postgresql-master-credentials"
  description = "POSTGRESQL master credentials"
}
resource "aws_secretsmanager_secret_version" "postgresql_passwords_version" {
  secret_id = aws_secretsmanager_secret.postgresql_passwords.id
  secret_string = jsonencode({
    dbusername   = "pgadmin",
    dev-password = "NO-PASS-HERE",
    tst-password = "NO-PASS-HERE",
    stg-password = "NO-PASS-HERE",
    pro-password = "NO-PASS-HERE"
  })
}

# Private subnet for instances of admin tasks

data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "private_in_default" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.64.0/20" # adjust as needed
  availability_zone = "eu-west-2a"

  tags = {
    Name = "default-private-subnet"
    Type = "private"
  }
  depends_on = [aws_nat_gateway.default_ngw]
}

resource "aws_route_table" "private_rtb" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_in_default.id
  route_table_id = aws_route_table.private_rtb.id
}




data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "public_second" {
  id = data.aws_subnets.default.ids[1]
}



data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
resource "aws_eip" "default_ngw" {
  domain = "vpc"
  tags = {
    "Name" = "dm-gen-ElasticIP"
  }
}


resource "aws_nat_gateway" "default_ngw" {
  allocation_id = aws_eip.default_ngw.id
  subnet_id     = data.aws_subnet.public_second.id

  tags = {
    Name = "default-vpc-nat-gw"
  }
}


resource "aws_route" "private_to_internet" {
  route_table_id         = aws_route_table.private_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default_ngw.id
}
