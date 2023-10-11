
resource "aws_security_group" "efs-sg" {
  name        = "${var.project_code}-${var.env_name}-eks-sg"
  description = "Allow NFS inbound traffic"
  vpc_id      = var.eks_vpc_id

  ingress {
    description      = "NFS from VPC"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}



resource "aws_efs_file_system" "eks" {
  creation_token = "eks-${var.env_name}"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  # lifecycle_policy {
  #   transition_to_ia = "AFTER_30_DAYS"
  # }

  tags = {
    Name = "${var.project_code}-${var.env_name}-efs"
  }
}

resource "aws_efs_mount_target" "zone-a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = var.private_subnet_one_id
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_efs_mount_target" "zone-b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = var.private_subnet_two_id
  security_groups = [aws_security_group.efs-sg.id]
}
