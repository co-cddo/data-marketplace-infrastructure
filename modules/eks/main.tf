//IAM role for EKS - used to make API calls to AWS services
//i.e. to create managed node pools


provider "kubernetes" {
  config_path = "~/.kube/config"
}


resource "aws_iam_role" "eks-cluster-role" {
  name = "${var.project_code}-${var.env_name}-role-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// Attach AmazonEKSClusterPolicy

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

//EKS cluster

resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_code}-${var.env_name}-eks-cluster"
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-cluster-role.arn
  vpc_config {

    endpoint_private_access = true
    endpoint_public_access  = false
    // public_access_cidrs     = ["0.0.0.0/0"]
    //need to improve this code and not use 0 and 1 
    subnet_ids = [
      var.private_subnet_one_id,
      var.private_subnet_two_id,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon-eks-cluster-policy,
  ]

  tags = merge(
    var.tags,
    {
      vpc_dependency = var.network_dependency
    }
  )

}
data "aws_security_group" "eks_cluster_sg" {
  id = data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "allow_peered_vpc_to_control_plane" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["172.31.0.0/16"]
  security_group_id = data.aws_security_group.eks_cluster_sg.id
  description       = "Allow peered VPC private subnet CIDR to access EKS control plane"
}

# custom controllers need this config (loadbalancer, external secret)
resource "null_resource" "eks_kubeconfig_update" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.cluster.name} --region ${var.region}"
  }

  depends_on = [
    aws_eks_cluster.cluster,
    aws_security_group_rule.allow_peered_vpc_to_control_plane
  ]
}


data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "oidcprovider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = {
    ProjectCode = "${var.project_code}"
    Environment = "${var.env_name}"
  }
}

# For accessing from aws console
resource "null_resource" "cluster" {

  # depends_on = [null_resource.awscli]
  depends_on = [
    aws_eks_cluster.cluster,
    aws_security_group_rule.allow_peered_vpc_to_control_plane
  ]


  provisioner "local-exec" {
    command = "sleep 45 && kubectl apply -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml"
  }
}

resource "aws_iam_role" "eks-fargate-profile-role" {
  name = "${var.project_code}-${var.env_name}-role-eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile-role.name
}


resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile-role.arn
  subnet_ids = [
    var.private_subnet_one_id,
    var.private_subnet_two_id
  ]

  selector {
    namespace = "kube-system"
    labels    = {}
  }
}


resource "aws_eks_fargate_profile" "fp-app" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "fp-app"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile-role.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    var.private_subnet_one_id,
    var.private_subnet_two_id
  ]

  selector {
    namespace = "app"
    labels    = {}
  }
}




# Generic Role and ServiceAccount for Pods to call AWS services
data "aws_iam_policy_document" "aws-sa_assumerole_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidcprovider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.app_namespace}:${var.sa_name}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidcprovider.arn]
      type        = "Federated"
    }
  }
}
resource "aws_iam_policy" "aws_sa_role_policy" {
  policy = file("${path.module}/aws-sa-role-policy.json")
  name   = "${var.project_code}-${var.env_name}-policy-generic-aws-sa"
}
resource "aws_iam_role" "aws_sa_role" {
  assume_role_policy = data.aws_iam_policy_document.aws-sa_assumerole_trust.json
  name               = "${var.project_code}-${var.env_name}-role-eks-aws-generic-serviceaccount"
}
resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.aws_sa_role.name
  policy_arn = aws_iam_policy.aws_sa_role_policy.arn
}


// remove ec2 annotation from CoreDNS deployment
// Resolve CoreDNS pods in a Pending state
// https://repost.aws/knowledge-center/eks-resolve-pending-fargate-pods
// https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.cluster.id
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_update = "PRESERVE"


  configuration_values = jsonencode({
    computeType = "Fargate"
    # Ensure that the we fully utilize the minimum amount of resources that are supplied by
    # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
    # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
    # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
    # compute configuration that most closely matches the sum of vCPU and memory requests in
    # order to ensure pods always have the resources that they need to run.
    resources = {
      limits = {
        cpu = "0.25"
        # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
        # request/limit to ensure we can fit within that task
        memory = "256M"
      }
      requests = {
        cpu = "0.25"
        # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
        # request/limit to ensure we can fit within that task
        memory = "256M"
      }
    }
  })



  depends_on = [aws_eks_fargate_profile.kube-system]
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.cluster.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.cluster.name
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"

      args    = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.id]
      command = "aws"
    }

  }
}
