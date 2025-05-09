#data "aws_secretsmanager_secret" "db_password" {
#  name = "dm-gen-mssql-${var.env_name}-masterpassword"
#}
#
#data "aws_secretsmanager_secret_version" "db_password" {
#  secret_id = data.aws_secretsmanager_secret.db_password.id
#}



resource "aws_db_instance" "postgresql_instance" {
  identifier        = "${var.project_code}-${var.env_name}-rds-postgresql-instance"
  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t3.large"
  allocated_storage = 200
  storage_type      = "gp3"
  license_model     = "postgresql-license"

  username = "pgadmin"
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]


  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  multi_az               = false
  backup_retention_period = 7
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_code}-${var.env_name}-eks-sg"
  }
}

#resource "aws_db_subnet_group" "db_subnet_group" {
#  name       = "${var.project_code}-${var.env_name}-mssql-subnet-group"
#  subnet_ids = [var.private_subnet_one_id, var.private_subnet_two_id]
#
#  tags = {
#    Name = "POSTGRESQL DB Subnet Group"
#  }
#}
#
#resource "aws_security_group" "db_sg" {
#  name        = "${var.project_code}-${var.env_name}-mssql-sg"
#  description = "Security group for POSTGREQL RDS instance"
#  vpc_id      = var.eks_vpc_id
#
#  # Add ingress rules as needed
#  ingress {
#    from_port   = 5432
#    to_port     = 5432
#    protocol    = "tcp"
#    cidr_blocks = [var.vpc_cidr]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "POSTGRESQL Security Group"
#  }
#}
