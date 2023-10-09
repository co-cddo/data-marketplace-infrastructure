variable "region"{
    type = string
    default = "eu-west-2"
}
variable "project_code" {
    type = string
    default = "dm"
}
variable "env_name"   {
    type = string
    default = "dev"
}
#vpc vars
variable "vpc_cidr" {
    type = string 
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
    type = string
    default = "1.27"
}
variable "app_namespace" {
    type = string
    default = "app"
}
