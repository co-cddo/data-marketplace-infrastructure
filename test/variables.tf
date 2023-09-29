variable "vpc_cidr" {
    type = string 
    default = "10.11.0.0/16"
}
variable "private_subnets" {
    default = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"] 
}
variable "public_subnets" { 
    default = ["10.11.4.0/24", "10.11.5.0/24", "10.11.6.0/24"]
}
variable "test_env_name"   {
    type = string
    default = "test"
}
variable "project_code" {
    type = string
    default = "dm"
}
variable "cluster_name" {
    type = string
    default = "dm-eks-test"
}
variable "cluster_version" {
    type = string
    default = "1.27"
}
variable "region" {
  type = string
  default = "eu-north-1"
}