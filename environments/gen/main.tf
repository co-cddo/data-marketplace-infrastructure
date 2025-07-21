data "aws_caller_identity" "current" {}

resource "aws_kms_key" "state_backend_bucket_kms_key" {
  description             = "Encrypt the state bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "state_backend_bucket" {
  bucket = var.account_type == "prod" ? "dm-gen-config-${var.account_type}" : "dm-gen-config"
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

#-------------------------------------------------
#-- NEW                                      START
#-------------------------------------------------
resource "aws_iam_role_policy" "adm_ec2_profile_policy" {
  name = "adm_ec2_profile_policy"
  role = aws_iam_role.my_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:Decrypt",
                "kms:GenerateDataKey",
                "kms:CreateKey",
                "kms:ScheduleKeyDeletion",
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:CreateSecret",
                "secretsmanager:PutSecretValue",
                "secretsmanager:DeleteSecret",
                "ec2:DescribeVpcs",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeVpcAttribute",
                "ec2:DescribeRouteTables",
                "ec2:CreateVpc",
                "ec2:CreateTags",
                "ec2:ModifyVpcAttribute",
                "ec2:DeleteVpc",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSubnet",
                "ec2:CreateInternetGateway",
                "ec2:CreateRouteTable",
                "ec2:CreateVpcPeeringConnection",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:AttachInternetGateway",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteInternetGateway",
                "ec2:DeleteVpcPeeringConnection",
                "ec2:DeleteSubnet",
                "ec2:DeleteSecurityGroup",
                "ec2:CreateRoute",
                "ec2:AcceptVpcPeeringConnection",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:AssociateRouteTable",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AllocateAddress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:DescribeAddresses",
                "ec2:DescribeAddressesAttribute",
                "ec2:ReleaseAddress",
                "ec2:CreateNatGateway",
                "ec2:DescribeNatGateways",
                "ec2:DeleteNatGateway",
                "ec2:DescribeSecurityGroupRules",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteRoute",
                "ec2:DisassociateRouteTable",
                "ec2:DetachInternetGateway",
                "ec2:DeleteRouteTable",
                "ec2:DisassociateAddress",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:CreateCluster",
                "eks:TagResource",
                "eks:CreateFargateProfile",
                "eks:DescribeFargateProfile",
                "eks:DeleteFargateProfile",
                "eks:CreateAddon",
                "eks:DescribeAddon",
                "eks:DeleteAddon",
                "eks:DeleteCluster",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:CreateBucket",
                "s3:ListBucketVersions",
                "s3:GetAccountPublicAccessBlock",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketPolicyStatus",
                "s3:GetBucketAcl",
                "s3:ListAccessPoints",
                "s3:GetBucketPolicy",
                "s3:GetBucketCORS",
                "s3:GetBucketWebsite",
                "s3:GetBucketVersioning",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketRequestPayment",
                "s3:GetBucketLogging",
                "s3:GetLifecycleConfiguration",
                "s3:GetReplicationConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetBucketTagging",
                "s3:DeleteBucket",
                "s3:PutBucketVersioning",
                "s3:PutEncryptionConfiguration",
                "s3:PutBucketPublicAccessBlock",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:GetRole",
                "iam:GetPolicy",
                "iam:ListRolePolicies",
                "iam:GetPolicyVersion",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicyVersions",
                "iam:ListInstanceProfilesForRole",
                "iam:DeletePolicy",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "iam:CreateOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:GetOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:DetachRolePolicy",
                "ssm:DescribeParameters",
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "ssm:ListTagsForResource",
                "rds:CreateDBSubnetGroup",
                "rds:AddTagsToResource",
                "rds:DescribeDBSubnetGroups",
                "rds:ListTagsForResource",
                "rds:DeleteDBSubnetGroup",
                "rds:RestoreDBInstanceFromDBSnapshot",
                "rds:DescribeDBInstances",
                "rds:DeleteDBInstance",
                "rds:ModifyDBInstance"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}
#------------------------------------------FINISH-

# Create an IAM role
resource "aws_iam_role" "adm_ec2_profile_role" {
  name = var.adm_ec2_profile_role_name

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

#-------------------------------------------------
#-- NEW                                      START
#-------------------------------------------------
# Fetch Policy ARN
data "aws_iam_policy" "adm_ec2_profile_policy_arn" {
  arn = "arn:aws:iam::aws:policy/adm_ec2_profile_policy"
  depends_on = [ aws_iam_role_policy.adm_ec2_profile_policy ]
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "adm_ec2_profile_policy_attachment" {
  role       = aws_iam_role.adm_ec2_profile_role.name
  policy_arn = data.aws_iam_policy.adm_ec2_profile_policy_arn.arn
  depends_on = [aws_iam_role_policy.adm_ec2_profile_policy]
}
#------------------------------------------FINISH-
## Attach the IAM policy to the IAM role
#resource "aws_iam_role_policy_attachment" "admin_access" {
#  role       = aws_iam_role.adm_ec2_profile_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
#}

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
      merge(
        {
          Effect = "Allow"
          Principal = {
            AWS = concat(
              ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
              var.account_type == "prod" ? [
                "arn:aws:iam::622626885786:user/soydaner.ulker@digital.cabinet-office.gov.uk",
                "arn:aws:iam::622626885786:user/john.palmer@digital.cabinet-office.gov.uk"
              ] : []
            )
          }
          Action = "sts:AssumeRole"
          Condition = merge(
            {
              Bool = {
                "aws:MultiFactorAuthPresent" = "true"
              }
            },
            var.account_type == "prod" ? {
              IpAddress = {
                "aws:SourceIp" = [
                  "217.196.229.77/32",
                  "217.196.229.79/32",
                  "217.196.229.80/32",
                  "217.196.229.81/32",
                  "51.149.8.0/25",
                  "51.149.8.128/29"
                ]
              }
            } : {}
          )
        }
      )
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
        "Resource": [
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-dev-logs:*",
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-stg-logs:*",
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-tst-logs:*",
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-pro-logs:*"
                    ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ],
        "Resource": [
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-dev-logs:*",
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-stg-logs:*",
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-tst-logs:*",
                      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:dm-fast-pro-logs:*"
                    ]
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
          AWS = concat(
            ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
            var.account_type == "prod" ? [
              "arn:aws:iam::622626885786:user/soydaner.ulker@digital.cabinet-office.gov.uk",
              "arn:aws:iam::622626885786:user/john.palmer@digital.cabinet-office.gov.uk"
            ] : []
          )
        }
        Action = "sts:AssumeRole"
        Condition = merge(
          {
            Bool = {
              "aws:MultiFactorAuthPresent" = "true"
            }
          },
          var.account_type == "prod" ? {
            IpAddress = {
              "aws:SourceIp" = [
                "217.196.229.77/32",
                "217.196.229.79/32",
                "217.196.229.80/32",
                "217.196.229.81/32",
                "51.149.8.0/25",
                "51.149.8.128/29"
              ]
            }
          } : {}
        )
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
