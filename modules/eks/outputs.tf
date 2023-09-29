output "eks_cluster" {
    value = aws_eks_cluster.cluster
}
output "eks_fargate_profile_kubesystem" {
    value = aws_eks_fargate_profile.kube-system
}
output "eks_fargate_profile_staging" {
    value = aws_eks_fargate_profile.staging
}
output "iam_fargate" {
    value = aws_iam_role.eks-fargate-profile
}