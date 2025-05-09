variable "region" {
  type    = string
  default = "eu-west-2"
}
variable "project_code" {
  type    = string
  default = "dm"
}
variable "env_name" {
  type    = string
  default = "tst"
}
#vpc vars
variable "vpc_cidr" {
  type    = string
  default = "10.11.0.0/16"
}
variable "private_subnets" {
  default = ["10.11.3.0/24", "10.11.4.0/24"]
}
variable "public_subnets" {
  default = ["10.11.1.0/24", "10.11.2.0/24"]
}
# eks cluster vars
variable "cluster_version" {
  type    = string
  default = "1.32"
}
variable "app_namespace" {
  type    = string
  default = "app"
}
#-------------------------------------------------
#-- MSSQL
#-------------------------------------------------
variable "rds_mssql_engine" {
  type    = string
  default = "sqlserver-ex"
}
variable "rds_mssql_engine_version" {
  type    = string
  default = "16.00.4185.3.v1"
}
variable "rds_mssql_instance_class" {
  type    = string
  default = "db.t3.large"
}
variable "rds_mssql_allocated_storage" {
  type    = number
  default = 200
}
variable "rds_mssql_storage_type" {
  type    = string
  default = "gp3"
}
variable "rds_mssql_license_model" {
  type    = string
  default = "license-included"
}
variable "rds_mssql_username" {
  type    = string
  default = "admin"
}
variable "rds_mssql_multi_az" {
  type    = bool
  default = false
}
variable "rds_mssql_backup_retention_period" {
  type    = number
  default = 7
}
variable "rds_mssql_skip_final_snapshot" {
  type    = bool
  default = true
}
#-------------------------------------------------
#-- POSTGRES
#-------------------------------------------------
variable "rds_postgres_engine" {
  type    = string
  default = "postgres"
}
variable "rds_postgres_engine_version" {
  type    = string
  default = "16.6"
}
variable "rds_postgres_instance_class" {
  type    = string
  default = "db.t3.large"
}
variable "rds_postgres_allocated_storage" {
  type    = number
  default = 200
}
variable "rds_postgres_storage_type" {
  type    = string
  default = "gp3"
}
variable "rds_postgres_license_model" {
  type    = string
  default = "postgresql-license"
}
variable "rds_postgres_username" {
  type    = string
  default = "pgadmin"
}
variable "rds_postgres_multi_az" {
  type    = bool
  default = false
}
variable "rds_postgres_backup_retention_period" {
  type    = number
  default = 7
}
variable "rds_postgres_skip_final_snapshot" {
  type    = bool
  default = true
}
#-------------------------------------------------


