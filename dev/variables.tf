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
  default = "dev"
}
#vpc vars
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "private_subnets" {
  default = ["10.10.3.0/24", "10.10.4.0/24"]
}
variable "public_subnets" {
  default = ["10.10.1.0/24", "10.10.2.0/24"]
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
  default = 200
}
variable "rds_storage_type" {
  type    = string
  default = "gp3"
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_backup_retention_period" {
  type    = number
  default = 7
}

