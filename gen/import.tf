import {
  to = aws_s3_bucket.state_backend_bucket
  id = "dm-gen-config"
}

import {
  to = aws_iam_policy.devops_iam_policy
  id = "arn:aws:iam::855859226163:policy/dm-gen-devops-policy"
}

import {
  to = aws_iam_role.devops_role
  id = var.devops_role_name
}


import {
  to = aws_iam_policy.developer_iam_policy
  id = "arn:aws:iam::855859226163:policy/dm-gen-policy-developer-name"
}

import {
  to = aws_s3_bucket_versioning.state_backend_bucket_versioning
  id = "dm-gen-config"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.state_backend_bucket_encryption
  id = "dm-gen-config"
}

import {
  to = aws_s3_bucket_public_access_block.state_backend_bucket_acl
  id = "dm-gen-config"
}

import {
  to = aws_iam_role.developer_role
  id = var.developer_role_name
}

import {
  to = aws_iam_role.readonly_role
  id = var.readonly_role_name
}

import {
  to = aws_kms_key.state_backend_bucket_kms_key
  id = "arn:aws:kms:eu-west-2:855859226163:key/99c8b276-fbc0-4c0c-8e32-d38c6f31de31"
}
