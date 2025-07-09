output "eks_cluster" {
  value = aws_eks_cluster.cluster
}

output "eks_fargate_profile_kubesystem" {
  value = aws_eks_fargate_profile.kube-system
}

output "eks_fargate_profile_app" {
  value = aws_eks_fargate_profile.fp-app
}
output "iam_fargate" {
  value = aws_iam_role.eks-fargate-profile-role
}

output "openid_connector" {
  value = aws_iam_openid_connect_provider.oidcprovider
}

output "secgroup_allow_peered_vpc_to_control_plane" {
  value = aws_security_group_rule.allow_peered_vpc_to_control_plane
}

