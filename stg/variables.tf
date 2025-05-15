variable "region" {
  type    = string
  default = "eu-west-2"
}
variable "project_code" {
  type    = string
  default = "dm"
}
# DO NOT FORGET TO UPDATE BACKEND FILE ALSO
variable "env_name" {
  type    = string
  default = "stg"
}
#vpc vars
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "private_subnets" {
  default = ["10.20.3.0/24", "10.20.4.0/24"]
}
variable "public_subnets" {
  default = ["10.20.1.0/24", "10.20.2.0/24"]
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
variable "rds_engine" {
  type    = string
  default = "sqlserver-ex"
}
variable "rds_engine_version" {
  type    = string
  default = "16.00.4185.3.v1"
}
variable "rds_instance_class" {
  type    = string
  default = "db.t3.large"
}
variable "rds_allocated_storage" {
  type    = number
  default = 30
}
variable "rds_storage_type" {
  type    = string
  default = "gp3"
}
variable "rds_mssql_license_model" {
  type    = string
  default = "license-included"
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_backup_retention_period" {
  type    = number
  default = 7
}
variable "rds_mssql_skip_final_snapshot" {
  type    = bool
  default = true
}
variable "rds_mssql_snapshot_identifier" {
  type = string
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
variable "rds_postgres_snapshot_identifier" {
  type = string
}
#-------------------------------------------------
