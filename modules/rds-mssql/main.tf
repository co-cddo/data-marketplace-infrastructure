data "aws_secretsmanager_secret" "db_password" {
  name = "dm-gen-mssql-master-credentials"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}



resource "aws_db_instance" "mssql_instance" {
  identifier              = "${var.project_code}-${var.env_name}-rds-mssql-instance"
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  storage_type            = var.rds_storage_type
  storage_encrypted	  = false
  license_model           = var.rds_mssql_license_model
  username                = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["dbusername"]
  password                = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["dev-password"]
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = var.rds_mssql_skip_final_snapshot
  snapshot_identifier     = var.rds_mssql_snapshot_identifier != "" ? var.rds_mssql_snapshot_identifier : null

  tags = {
    Name = "${var.project_code}-${var.env_name}-eks-sg"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_code}-${var.env_name}-mssql-subnet-group"
  subnet_ids = [var.private_subnet_one_id, var.private_subnet_two_id]

  tags = {
    Name = "MSSQL DB Subnet Group"
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_code}-${var.env_name}-mssql-sg"
  description = "Security group for MSSQL RDS instance"
  vpc_id      = var.eks_vpc_id

  # Add ingress rules as needed
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MSSQL Security Group"
  }
}
