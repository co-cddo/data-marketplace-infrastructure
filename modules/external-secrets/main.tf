provider "kubernetes" {
  config_path = "~/.kube/config"
}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "aws_eks_fargate_profile" "externalsecrets" {
  cluster_name           = var.eks_cluster.name
  fargate_profile_name   = "externalsecret"
  pod_execution_role_arn = var.iam_fargate.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    var.private_subnet_one_id,
    var.private_subnet_two_id
  ]

  selector {
    namespace = "external-secrets"
    labels    = {}
  }
}

# service account
data "aws_iam_policy_document" "sa_assumerole_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.openid_connector.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.sa_namespace}:${var.sa_name}"]
    }

    principals {
      identifiers = [var.openid_connector.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "sa_role" {
  assume_role_policy = data.aws_iam_policy_document.sa_assumerole_trust.json
  name               = "${var.project_code}-${var.env_name}-role-eks-externalsecrets"
}

resource "aws_iam_policy" "sa_role_policy" {
#  policy = file("${path.module}/sa-role-policy.json")
  name   = "${var.project_code}-${var.env_name}-policy-externalsecrets"


  policy = jsonencode (
        {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.project_code}/${var.env_name}/*",
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.sa_role.name
  policy_arn = aws_iam_policy.sa_role_policy.arn
}

resource "helm_release" "external-secrets" {
  name             = "${var.eks_cluster.name}-external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  verify           = "false"
  namespace        = "external-secrets"
  create_namespace = true
  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "webhook.port"
    value = 9443
  }
  depends_on = [aws_eks_fargate_profile.externalsecrets, var.network_dependency]
}
