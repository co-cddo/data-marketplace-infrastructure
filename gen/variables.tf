variable "region" {
  type    = string
  default = "eu-west-2"
}
variable "account_type" {
  type        = string
  description = "prod | dev" 
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
variable "adm_ec2_profile_role_name" {
  type    = string
  default = "dm-gen-ec2-profile-role"
}
