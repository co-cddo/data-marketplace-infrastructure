resource "aws_efs_file_system" "eks" {
  creation_token = "eks-${var.env_name}"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  # lifecycle_policy {
  #   transition_to_ia = "AFTER_30_DAYS"
  # }

  tags = {
    Name = "dm-eks-filesystem-${var.env_name}"
  }
}

resource "aws_efs_mount_target" "zone-a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = var.private_subnet_one_id
  security_groups = [var.eks_cluster.vpc_config[0].cluster_security_group_id]
}

resource "aws_efs_mount_target" "zone-b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = var.private_subnet_two_id
  security_groups = [var.eks_cluster.vpc_config[0].cluster_security_group_id]
}
