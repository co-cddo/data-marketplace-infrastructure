//IAM role for EKS - used to make API calls to AWS services
//i.e. to create managed node pools


provider "kubernetes" {
  config_path    = "~/.kube/config"
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
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    //need to improve this code and not use 0 and 1 
    subnet_ids = [
        var.private_subnet_one_id,
        var.private_subnet_two_id,
        var.public_subnet_one_id,
        var.public_subnet_two_id
    ]
  }

  # csutom controllers need this config (loadbalancer, external secret)
  provisioner "local-exec" {
    command =  "aws eks update-kubeconfig --name ${var.project_code}-${var.env_name}-eks-cluster --region ${var.region}"

  }


  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}


resource "kubernetes_namespace" "ns-app" {
  metadata {
    name = var.app_namespace
  }
}



data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "oidcprovider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# csutom controllers need this config (loadbalancer, external secret)
resource "null_resource" "awscli"{
    depends_on = [aws_eks_cluster.cluster]
    provisioner "local-exec" {
    command =  "aws eks update-kubeconfig --name ${var.project_code}-${var.env_name}-eks-cluster  --region ${var.region}"
  }
}

# For accessing from aws console
resource "null_resource" "cluster" {

  depends_on = [null_resource.awscli]

  provisioner "local-exec" {
    command = "kubectl apply -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml"
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
  }
}





// remove ec2 annotation from CoreDNS deployment
// Resolve CoreDNS pods in a Pending state
// https://repost.aws/knowledge-center/eks-resolve-pending-fargate-pods
// https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.cluster.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  triggers = {
    endpoint = aws_eks_cluster.cluster.endpoint
    ca_crt   = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.eks.token
  }

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)}
EOF
kubectl \
  --server="${aws_eks_cluster.cluster.endpoint}" \
  --certificate_authority=/tmp/ca.crt \
  --token="${data.aws_eks_cluster_auth.eks.token}" \
  patch deployment coredns \
  -n kube-system --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
EOH
  }

  lifecycle {
    ignore_changes = [triggers]
  }
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

      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.id]
      command     = "aws"
    } 
   
  }
}
/*
resource "helm_release" "metrics-server" {
    name = "metrics-server"

    repository       = "https://charts.bitnami.com/bitnami"
    chart            = "metrics-server"
    namespace        = "metrics-server"
    //version          = "5.11.1"
    create_namespace = true

    set {
        name  = "apiService.create"
        value = "true"
    }

  depends_on = [aws_eks_fargate_profile.kube-system]
}
*/

