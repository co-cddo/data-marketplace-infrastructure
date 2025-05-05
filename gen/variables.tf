variable "region" {
  type    = string
  default = "eu-west-2"
}
variable "dynamodb_tablename" {
  type    = string
  default = "dm-gen-dynamodb-terraform-lock-table"
}
variable "devops_policy_name" {
  type    = string
  default = "dm-gen-devops-policy"
}

variable "devops_role_name" {
  type    = string
  default = "dm-gen-role-devops"
}
variable "developer_policy_name" {
  type    = string
  default = "dm-gen-policy-developer"
}

variable "developer_role_name" {
  type    = string
  default = "dm-gen-role-developer"
}

variable "readonly_policy_name" {
  type    = string
  default = "dm-gen-policy-readonly"
}

variable "readonly_role_name" {
  type    = string
  default = "dm-gen-role-readonly"
}

variable "secretmanager_mssql_masterpass_dev_name" {
  type    = string
  default = "dm-gen-mssql-dev-masterpassword"
}
