provider "kubernetes" {
  config_path    = "~/.kube/config"
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
    namespace = "${var.eks_cluster.name}-external-secrets"
  }
}




resource "helm_release" "external-secrets" {
  name       = "${var.eks_cluster.name}-external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  verify     = "false"
  namespace  = "${var.eks_cluster.name}-external-secrets"
  create_namespace = true
  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "webhook.por"
    value = "9443"
    type  = "string"
  }
}

