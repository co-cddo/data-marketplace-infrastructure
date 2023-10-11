provider "kubernetes" {
  config_path    = "~/.kube/config"
}
provider "helm" {
  kubernetes {
   config_path = "~/.kube/config"
  }
}

//eks service account
data "aws_iam_policy_document" "sa_assumerole_trust" {
  statement{
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
  name               = "${var.project_code}-${var.env_name}-role-eks-aws-alb-controller"
}

resource "aws_iam_policy" "sa_role_policy" {
  policy = file("${path.module}/sa-role-policy.json")
  name   = "${var.project_code}-${var.env_name}-policy-eks-alb"
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.sa_role.name
  policy_arn = aws_iam_policy.sa_role_policy.arn
}

resource "helm_release" "aws-load-balancer-controller" {
  
  name       = "${var.project_code}-${var.env_name}-external-aws-alb-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  
  version = "1.4.1"

  set {
    name  = "clusterName"
    value = var.eks_cluster.id
  }
  set {
    name = "image.repository"
    value = "public.ecr.aws/eks/aws-load-balancer-controller"
  }

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "serviceAccount.name"
    value = var.sa_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.sa_role.arn
  }

  # EKS Fargate specific
  set {
    name  = "region"
    value = "${var.region}"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  timeout = 600
  depends_on = [var.eks_fargate_profile_kubesystem ]
}

