provider "aws" {
  region = var.region
}

locals {
  tags = {
    Project     = "Data-Marketplace"
    Environment = var.env_name
    Team        = "CDDO"
  }
}

module "vpcmodule" {
  source = "../modules/vpc"

  cidr_vpc        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  env_name        = var.env_name
  project_code    = var.project_code

  cluster_name    = "${var.project_code}-${var.env_name}-eks-cluster"
  cluster_version = var.cluster_version

}

module "eks_cluster" {
  source                = "../modules/eks"
  project_code          = var.project_code
  env_name              = var.env_name
  cluster_version       = var.cluster_version
  private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
  private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
  public_subnet_one_id  = module.vpcmodule.public_subnets_output[0]
  public_subnet_two_id  = module.vpcmodule.public_subnets_output[1]
  region                = var.region
  app_namespace         = var.app_namespace
  sa_name               = "aws-generic-sa"
  tags                  = local.tags
}

module "load_balancer" {

  source                         = "../modules/load-balancer"
  vpc_id                         = module.vpcmodule.vpc.id
  eks_cluster                    = module.eks_cluster.eks_cluster
  project_code                   = var.project_code
  env_name                       = var.env_name
  eks_fargate_profile_kubesystem = module.eks_cluster.eks_fargate_profile_kubesystem
  # eks_fargate_profile_app = module.eks_cluster.eks_fargate_profile_app
  region           = var.region
  openid_connector = module.eks_cluster.openid_connector
  sa_name          = "aws-alb-sa"
  sa_namespace     = "kube-system"
}

module "external_secrets" {
  source                = "../modules/external-secrets"
  eks_cluster           = module.eks_cluster.eks_cluster
  project_code          = var.project_code
  iam_fargate           = module.eks_cluster.iam_fargate
  openid_connector      = module.eks_cluster.openid_connector
  env_name              = var.env_name
  region                = var.region
  private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
  private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
  sa_name               = "externalsecret-sa"
  sa_namespace          = var.app_namespace
}

module "mssql" {
  source                	= "../modules/rds"
  project_code          	= var.project_code
  private_subnet_one_id 	= module.vpcmodule.private_subnets_output[0]
  private_subnet_two_id 	= module.vpcmodule.private_subnets_output[1]
  env_name              	= var.env_name
  vpc_cidr              	= var.vpc_cidr
  eks_vpc_id            	= module.vpcmodule.vpc.id
  rds_engine			= var.rds_engine
  rds_engine_version		= var.rds_engine_version
  rds_instance_class		= var.rds_instance_class
  rds_allocated_storage 	= var.rds_allocated_storage
  rds_storage_type		= var.rds_storage_type
  rds_multi_az			= var.rds_multi_az
  rds_backup_retention_period 	= var.rds_backup_retention_period
}

module "app_params" {
  source = "../modules/parameter-store"
  prefix = "/${var.project_code}/${var.env_name}/appsettings/"
  securestring_parameters = [
    "ui",
    "api",
    "users",
    "datashare",
    "catalogue"
  ]
}
