resource "aws_eks_fargate_profile" "externalsecrets" {
  cluster_name           = var.eks_cluster.name
  fargate_profile_name   = "application"
  pod_execution_role_arn = var.iam_fargate.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    var.private_subnet_one_id,
    var.private_subnet_two_id
  ]

  selector {
    namespace = "application"
  }
}
# Policy
data "aws_iam_policy_document" "external_secrets" {
  count = var.enabled ? 1 : 0
  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ssm:GetParameter*"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "external_secrets" {
  depends_on  = [var.mod_dependency]
  count       = var.enabled ? 1 : 0
  name        = "${var.cluster_name}-external-secrets"
  path        = "/"
  description = "Policy for external secrets service"

  policy = data.aws_iam_policy_document.external_secrets[0].json
}

# Role
data "aws_iam_policy_document" "external_secrets_assume" {
  count = var.enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.openid_connector.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.openid_connector.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount::${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "external_secrets" {
  count              = var.enabled ? 1 : 0
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume[0].json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}

module "eks-irsa" {
  source  = "nalbam/eks-irsa/aws"
  version = "0.13.2"

  name = "apps_role_${var.env_name}"
  region = var.region
  cluster_name = var.eks_cluster.name
  cluster_names = [
    var.eks_cluster.name
  ]
  kube_namespace      = "${var.namespace}"
  kube_serviceaccount = "${var.service_account_name}"

  policy_arns = [
    aws_iam_policy.iamSecretPolicy.arn
  ]

  depends_on = [
    var.eks_cluster
  ]
}

resource "aws_iam_policy" "iamSecretPolicy" {
  name        = "${var.env_name}_secretPolicy"
  path        = "/"
  description = "Allow access to ${var.env_name} secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${var.region}:855859226163:secret:${var.env_name}/*"
        ]
      },
    ]
  })
}

resource "helm_release" "external-secrets-dev" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  verify     = "false"
  namespace  = "application"
  create_namespace = true
  values = [
    templatefile("${path.module}/helm/kubernetes-external-secrets/values.yml", { roleArn = "${module.eks-irsa.arn}" })
  ]
  set {
    name  = "createCRD"
    value = "true"
  }
  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "service.annotations.prometheus\\.io/port"
    value = "9127"
    type  = "string"
  }
}