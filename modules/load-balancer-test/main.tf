data "tls_certificate" "eks" {
  url = var.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = var.eks_cluster.identity[0].oidc[0].issuer
}

//eks service account
data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement{
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

  condition {
    test     = "StringEquals"
    variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
    values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
  }

  principals {
    identifiers = [aws_iam_openid_connect_provider.eks.arn]
    type        = "Federated"
  }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller-${var.env_name}"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("${path.module}/LBControllerTF.json")
  name   = "LBControllerTF-${var.env_name}"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}


resource "helm_release" "aws-load-balancer-controller-test" {
  name = "aws-load-balancer-controller"

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
  /*set {
    name  = "image.tag"
    value = "v2.3.0"
  }*/

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  # EKS Fargate specific
  set {
    name  = "region"
    value = "eu-north-1"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [var.eks_fargate_profile_kubesystem]
}