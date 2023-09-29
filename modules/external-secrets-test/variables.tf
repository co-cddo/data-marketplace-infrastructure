variable "eks_cluster" {}
variable "iam_fargate" {}
variable "cluster_name" {}
variable "openid_connector" {}
variable "env_name" {}
variable "region" {}

variable "private_subnet_one_id" {
    
}
variable "private_subnet_two_id" {

}
variable "enabled" {
  type    = bool
  default = true
}

variable "helm_chart_name" {
  type        = string
  default     = "external-secrets"
  description = "External Secrets chart name."
}

variable "helm_chart_release_name" {
  type        = string
  default     = "external-secrets"
  description = "External Secrets release name."
}

variable "helm_chart_repo" {
  type        = string
  default     = "https://charts.external-secrets.io"
  description = "External Secrets repository name."
}

variable "helm_chart_version" {
  type        = string
  default     = "0.7.1"
  description = "External Secrets chart version."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether to create k8s namespace with name defined by `namespace`"
}

variable "namespace" {
  type        = string
  default     = "application"
  description = "Kubernetes namespace to deploy EKS Spot termination handler Helm chart."
}

variable "service_account_name" {
  type        = string
  default     = "dm-frontend-sa"
  description = "External Secrets service account name"
}

variable "mod_dependency" {
  default     = null
  description = "Dependence variable binds all AWS resources allocated by this module, dependent modules reference this variable"
}

variable "settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets"
}