
resource "aws_kms_key" "state_backend_bucket_kms_key" {
  description             = "Encrypt the state bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket" "state_backend_bucket" {
  bucket = "dm-gen-configuration"

}
resource "aws_s3_bucket_versioning" "state_backend_bucket_versioning" {
  bucket  = aws_s3_bucket.state_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state_backend_bucket_encryption" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_backend_bucket_kms_key.arn
      sse_algorithm = "aws:kms"
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
            Bool: {
                "aws:MultiFactorAuthPresent": "true"
            }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "devops_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.devops_iam_policy.arn
  roles       = [aws_iam_role.devops_role.name]
}


// DEVELOPER ROLE

# Create an IAM policy
resource "aws_iam_policy" "developer_iam_policy" {
  name = var.developer_policy_name

  policy = jsonencode({

	Version: "2012-10-17",
	Statement= [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
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
			"Resource": "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/docker/mygroup:*"
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"logs:GetLogEvents",
				"logs:DescribeLogGroups"
			],
			"Resource": "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/docker/mygroup:*"
		},
		{
			"Sid": "VisualEditor2",
			"Effect": "Allow",
			"Action": [
				"logs:DescribeLogGroups",
				"logs:StartLiveTail",
				"logs:StopLiveTail",
				"logs:StopQuery",
				"logs:TestMetricFilter",
				"logs:GetLogDelivery",
				"logs:DescribeQueryDefinitions"
			],
			"Resource": "*"
		},
		{
			"Sid": "VisualEditor3",
			"Effect": "Allow",
			"Action": [
				"logs:DescribeLogStreams",
				"logs:GetLogEvents",
				"logs:DescribeLogGroups"
			],
			"Resource": "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/dm/docker/applications:*"
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
            Bool: {
                "aws:MultiFactorAuthPresent": "true"
            }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "developer_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.developer_iam_policy.arn
  roles       = [aws_iam_role.developer_role.name]
}

// READONLY ROLE

# Create an IAM policy
resource "aws_iam_policy" "readonly_iam_policy" {
  name = var.readonly_policy_name

  policy = jsonencode({

    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "a4b:Get*",
                "a4b:List*",
                "a4b:Search*",
                "access-analyzer:GetAccessPreview",
                "access-analyzer:GetAnalyzedResource",
                "access-analyzer:GetAnalyzer",
                "access-analyzer:GetArchiveRule",
                "access-analyzer:GetFinding",
                "access-analyzer:GetGeneratedPolicy",
                "access-analyzer:ListAccessPreviewFindings",
                "access-analyzer:ListAccessPreviews",
                "access-analyzer:ListAnalyzedResources",
                "access-analyzer:ListAnalyzers",
                "access-analyzer:ListArchiveRules",
                "access-analyzer:ListFindings",
                "access-analyzer:ListPolicyGenerations",
                "access-analyzer:ListTagsForResource",
                "access-analyzer:ValidatePolicy",
                "account:GetAccountInformation",
                "account:GetAlternateContact",
                "account:GetChallengeQuestions",
                "account:GetContactInformation",
                "account:GetRegionOptStatus",
                "account:ListRegions",
                "autoscaling-plans:Describe*",
                "autoscaling-plans:GetScalingPlanResourceForecastData",
                "autoscaling:Describe*",
                "autoscaling:GetPredictiveScalingForecast",
                "aws-portal:View*",
                "backup-gateway:ListGateways",
                "backup-gateway:ListHypervisors",
                "backup-gateway:ListTagsForResource",
                "backup-gateway:ListVirtualMachines",
                "backup:Describe*",
                "backup:Get*",
                "backup:List*",
                "batch:Describe*",
                "batch:List*",
                "billing:GetBillingData",
                "billing:GetBillingDetails",
                "billing:GetBillingNotifications",
                "billing:GetBillingPreferences",
                "billing:GetContractInformation",
                "billing:GetCredits",
                "billing:GetIAMAccessPreference",
                "billing:GetSellerOfRecord",
                "billing:ListBillingViews",
                "billingconductor:ListAccountAssociations",
                "billingconductor:ListBillingGroupCostReports",
                "billingconductor:ListBillingGroups",
                "billingconductor:ListCustomLineItems",
                "billingconductor:ListCustomLineItemVersions",
                "billingconductor:ListPricingPlans",
                "billingconductor:ListPricingPlansAssociatedWithPricingRule",
                "billingconductor:ListPricingRules",
                "billingconductor:ListPricingRulesAssociatedToPricingPlan",
                "billingconductor:ListResourcesAssociatedToCustomLineItem",
                "billingconductor:ListTagsForResource",           
                "directconnect:Describe*",
                "dynamodb:BatchGet*",
                "dynamodb:Describe*",
                "dynamodb:Get*",
                "dynamodb:List*",
                "dynamodb:PartiQLSelect",
                "dynamodb:Query",
                "dynamodb:Scan",
                "ec2:Describe*",
                "ec2:Get*",
                "ec2:ListImagesInRecycleBin",
                "ec2:ListSnapshotsInRecycleBin",
                "ec2:SearchLocalGatewayRoutes",
                "ec2:SearchTransitGatewayRoutes",
                "ec2messages:Get*",
                "ecr-public:BatchCheckLayerAvailability",
                "ecr-public:DescribeImages",
                "ecr-public:DescribeImageTags",
                "ecr-public:DescribeRegistries",
                "ecr-public:DescribeRepositories",
                "ecr-public:GetAuthorizationToken",
                "ecr-public:GetRegistryCatalogData",
                "ecr-public:GetRepositoryCatalogData",
                "ecr-public:GetRepositoryPolicy",
                "ecr-public:ListTagsForResource",
                "ecr:BatchCheck*",
                "ecr:BatchGet*",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:List*",
                "ecs:Describe*",
                "ecs:List*",
                "eks:Describe*",
                "eks:List*",
                "elasticfilesystem:Describe*",
                "elasticfilesystem:ListTagsForResource",
                "elasticloadbalancing:Describe*",                
                "iam:Generate*",
                "iam:Get*",
                "iam:List*",
                "iam:Simulate*",
                "identity-sync:GetSyncProfile",
                "identity-sync:GetSyncTarget",
                "identity-sync:ListSyncFilters",
                "identitystore-auth:BatchGetSession",
                "identitystore-auth:ListSessions",
                "identitystore:DescribeGroup",
                "identitystore:DescribeGroupMembership",
                "identitystore:DescribeUser",
                "identitystore:GetGroupId",
                "identitystore:GetGroupMembershipId",
                "identitystore:GetUserId",
                "identitystore:IsMemberInGroups",
                "identitystore:ListGroupMemberships",
                "identitystore:ListGroupMembershipsForMember",
                "identitystore:ListGroups",
                "identitystore:ListUsers",
                "kms:Describe*",
                "kms:Get*",
                "kms:List*",
                "lambda:Get*",
                "lambda:List*",
                "resource-groups:Get*",
                "resource-groups:List*",
                "resource-groups:Search*",
                "route53-recovery-cluster:Get*",
                "route53-recovery-cluster:ListRoutingControls",
                "route53-recovery-control-config:Describe*",
                "route53-recovery-control-config:List*",
                "route53-recovery-readiness:Get*",
                "route53-recovery-readiness:List*",
                "route53:Get*",
                "route53:List*",
                "route53:Test*",
                "route53domains:Check*",
                "route53domains:Get*",
                "route53domains:List*",
                "route53domains:View*",
                "route53resolver:Get*",
                "route53resolver:List*",
                "s3-object-lambda:GetObject",
                "s3-object-lambda:GetObjectAcl",
                "s3-object-lambda:GetObjectLegalHold",
                "s3-object-lambda:GetObjectRetention",
                "s3-object-lambda:GetObjectTagging",
                "s3-object-lambda:GetObjectVersion",
                "s3-object-lambda:GetObjectVersionAcl",
                "s3-object-lambda:GetObjectVersionTagging",
                "s3-object-lambda:ListBucket",
                "s3-object-lambda:ListBucketMultipartUploads",
                "s3-object-lambda:ListBucketVersions",
                "s3-object-lambda:ListMultipartUploadParts",
                "s3:DescribeJob",
                "s3:Get*",
                "s3:List*",
                "secretsmanager:Describe*",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:List*",
                "ssm-contacts:DescribeEngagement",
                "ssm-contacts:DescribePage",
                "ssm-contacts:GetContact",
                "ssm-contacts:GetContactChannel",
                "ssm-contacts:ListContactChannels",
                "ssm-contacts:ListContacts",
                "ssm-contacts:ListEngagements",
                "ssm-contacts:ListPageReceipts",
                "ssm-contacts:ListPagesByContact",
                "ssm-contacts:ListPagesByEngagement",
                "ssm-incidents:GetIncidentRecord",
                "ssm-incidents:GetReplicationSet",
                "ssm-incidents:GetResourcePolicies",
                "ssm-incidents:GetResponsePlan",
                "ssm-incidents:GetTimelineEvent",
                "ssm-incidents:ListIncidentRecords",
                "ssm-incidents:ListRelatedItems",
                "ssm-incidents:ListReplicationSets",
                "ssm-incidents:ListResponsePlans",
                "ssm-incidents:ListTagsForResource",
                "ssm-incidents:ListTimelineEvents",
                "ssm:Describe*",
                "ssm:Get*",
                "ssm:List*", 
                "vpc-lattice:GetAccessLogSubscription",
                "vpc-lattice:GetAuthPolicy",
                "vpc-lattice:GetListener",
                "vpc-lattice:GetResourcePolicy",
                "vpc-lattice:GetRule",
                "vpc-lattice:GetService",
                "vpc-lattice:GetServiceNetwork",
                "vpc-lattice:GetServiceNetworkServiceAssociation",
                "vpc-lattice:GetServiceNetworkVpcAssociation",
                "vpc-lattice:GetTargetGroup",
                "vpc-lattice:ListAccessLogSubscriptions",
                "vpc-lattice:ListListeners",
                "vpc-lattice:ListRules",
                "vpc-lattice:ListServiceNetworks",
                "vpc-lattice:ListServiceNetworkServiceAssociations",
                "vpc-lattice:ListServiceNetworkVpcAssociations",
                "vpc-lattice:ListServices",
                "vpc-lattice:ListTagsForResource",
                "vpc-lattice:ListTargetGroups",
                "vpc-lattice:ListTargets",
           
               
            ],
            "Resource": "*"
        }
    ]

  })
}

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
            Bool: {
                "aws:MultiFactorAuthPresent": "true"
            }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "readonly_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.readonly_iam_policy.arn
  roles       = [aws_iam_role.readonly_role.name]
}
