#resource "aws_iam_role" "ssm_role" {
#  name = "SSMRole_jp_sandbox"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Effect = "Allow",
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        },
#        Action = "sts:AssumeRole"
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "ssm_attach" {
#  role       = aws_iam_role.ssm_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

#data "aws_ami" "ubuntu_ami" {
#  most_recent = true
#  filter {
#    name = "name"
#    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
#  }
#  filter{
#    name = "virtualization-type"
#    values = ["hvm"]
#  }
#  owners = ["099720109477"]
#}

resource "aws_instance" "ec2_instance" {
  count                       = var.ec2_instance_count
  ami                         = var.ec2_instance_ami
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_instance_keypair
  vpc_security_group_ids      = var.ec2_instance_security_group_ids
  associate_public_ip_address = var.ec2_associate_public_ip_address
  subnet_id                   = var.ec2_instance_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data                   = var.ec2_user_data
  tags                        = var.ec2_instance_tags
  lifecycle {
    create_before_destroy = true
  }


  root_block_device {
    volume_size = var.ec2_root_volume_size
    volume_type = var.ec2_root_volume_type
    encrypted   = var.ec2_root_volume_encrypted
   #kms_key_id  = data.aws_kms_key.customer_master_key.arn
  }

  depends_on = [aws_iam_instance_profile.ssm_profile, aws_iam_role_policy_attachment.ssm_attach]

}
