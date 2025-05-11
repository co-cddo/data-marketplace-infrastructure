data "aws_secretsmanager_secret" "db_password" {
  name = "dm-gen-mssql-masterpassword-stg"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}



resource "aws_db_instance" "mssql_instance" {
  identifier              = "${var.project_code}-${var.env_name}-rds-mssql-instance"
  engine                  = "sqlserver-ex"
  engine_version          = "16.00.4185.3.v1"
  instance_class          = "db.t3.large"
  allocated_storage       = 200
  storage_type            = "gp3"
  license_model           = var.rds_mssql_license_model
  username                = var.rds_mssql_username
  password                = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  multi_az                = false
  backup_retention_period = 7
  skip_final_snapshot     = var.rds_mssql_skip_final_snapshot

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

resource "aws_security_group" "db_sg" {
  name        = "${var.project_code}-${var.env_name}-mssql-sg"
  description = "Security group for MSSQL RDS instance"
  vpc_id      = var.eks_vpc_id

  # Add ingress rules as needed
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
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
