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
variable "tags" { default = {} }
variable "coredns_version" { default = "v1.11.4-eksbuild.2" }
