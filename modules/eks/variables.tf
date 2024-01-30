variable "region" {}
variable "project_code" {}
variable "env_name" {}
variable "cluster_version" {}
variable "private_subnet_one_id" {}
variable "private_subnet_two_id" {}
variable "public_subnet_one_id" {}
variable "public_subnet_two_id" {}
variable "app_namespace" {}
variable "sa_name" {}
variable "enable_coredns" {}
variable "coredns_version" { default = "v1.10.1-eksbuild.7"}
