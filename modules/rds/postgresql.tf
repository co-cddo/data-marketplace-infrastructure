resource "aws_db_instance" "postgresql_instance" {
  identifier        = "${var.project_code}-${var.env_name}-rds-postgresql-instance"
  engine            = "postgres"
  engine_version    = "17.4"
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
