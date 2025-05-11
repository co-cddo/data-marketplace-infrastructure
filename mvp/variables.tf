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
  default = "mvp"
}
variable "vpc_cidr" {
  type    = string
  default = "10.12.0.0/16"
}
variable "private_subnets" {
  default = ["10.12.1.0/24", "10.12.2.0/24", "10.12.3.0/24"]
}
variable "public_subnets" {
  default = ["10.12.4.0/24", "10.12.5.0/24", "10.12.6.0/24"]
}
variable "cluster_version" {
  type    = string
  default = "1.27"
}
variable "app_namespace" {
  type    = string
  default = "app"
}
