data "aws_secretsmanager_secret" "db_password" {
  name = "dm-gen-postgresql-master-credentials"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

resource "aws_db_instance" "postgresql_instance" {
  identifier                  = "${var.project_code}-${var.env_name}-rds-postgresql-instance"
  engine                      = var.rds_postgres_engine
  engine_version              = var.rds_postgres_engine_version
  instance_class              = var.rds_postgres_instance_class
  allocated_storage           = var.rds_postgres_allocated_storage
  storage_type                = var.rds_postgres_storage_type
  license_model               = var.rds_postgres_license_model
  username                    = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["dbusername"]
  password                    = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["dev-password"]
  vpc_security_group_ids      = [aws_security_group.postgres_db_sg.id]
  db_subnet_group_name        = aws_db_subnet_group.postgres_db_subnet_group.name
  multi_az                    = var.rds_postgres_multi_az
  backup_retention_period     = var.rds_postgres_backup_retention_period
  skip_final_snapshot         = var.rds_postgres_skip_final_snapshot
  snapshot_identifier         = var.rds_postgres_snapshot_identifier != "" ? var.rds_postgres_snapshot_identifier : null
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade

  tags = {
    Name = "${var.project_code}-${var.env_name}-eks-sg"
  }
}

resource "aws_db_subnet_group" "postgres_db_subnet_group" {
  name       = "${var.project_code}-${var.env_name}-postgres-subnet-group"
  subnet_ids = [var.private_subnet_one_id, var.private_subnet_two_id]

  tags = {
    Name = "POSTGRES DB Subnet Group"
  }
}

resource "aws_security_group" "postgres_db_sg" {
  name        = "${var.project_code}-${var.env_name}-postgres-sg"
  description = "Security group for POSTGRES RDS instance"
  vpc_id      = var.eks_vpc_id

  # Add ingress rules as needed
  #Postgresql ingress port
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    // TODO: make it more parametric!
    cidr_blocks = ["172.31.0.0/16"]
    description = "FromDefaultVPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "POSTGRES Security Group"
  }
}
