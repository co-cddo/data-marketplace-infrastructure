provider "aws" {
  region = var.region
}

locals {
  tags = {
    Project     = "Data-Marketplace"
    Environment = var.env_name
    Team        = "DataShare"
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
  source                	           = "../modules/rds-mssql"
  project_code          	           = var.project_code
  private_subnet_one_id 	           = module.vpcmodule.private_subnets_output[0]
  private_subnet_two_id 	           = module.vpcmodule.private_subnets_output[1]
  env_name              	           = var.env_name
  vpc_cidr              	           = var.vpc_cidr
  eks_vpc_id            	           = module.vpcmodule.vpc.id
  rds_mssql_engine                   = var.rds_mssql_engine
  rds_mssql_engine_version           = var.rds_mssql_engine_version
  rds_mssql_instance_class           = var.rds_mssql_instance_class
  rds_mssql_allocated_storage        = var.rds_mssql_allocated_storage
  rds_mssql_storage_type             = var.rds_mssql_storage_type
  rds_mssql_multi_az                 = var.rds_mssql_multi_az
  rds_mssql_backup_retention_period  = var.rds_mssql_backup_retention_period
  rds_mssql_skip_final_snapshot      = var.rds_mssql_skip_final_snapshot
  rds_mssql_license_model            = var.rds_mssql_license_model
  rds_mssql_username                 = var.rds_mssql_username
}

module "postgres" {
  source                	             = "../modules/rds-postgres"
  project_code          	             = var.project_code
  private_subnet_one_id 	             = module.vpcmodule.private_subnets_output[0]
  private_subnet_two_id 	             = module.vpcmodule.private_subnets_output[1]
  env_name              	             = var.env_name
  vpc_cidr              	             = var.vpc_cidr
  eks_vpc_id            	             = module.vpcmodule.vpc.id
  rds_postgres_engine                  = var.rds_postgres_engine
  rds_postgres_engine_version          = var.rds_postgres_engine_version
  rds_postgres_instance_class          = var.rds_postgres_instance_class
  rds_postgres_allocated_storage       = var.rds_postgres_allocated_storage
  rds_postgres_storage_type            = var.rds_postgres_storage_type
  rds_postgres_multi_az                = var.rds_postgres_multi_az
  rds_postgres_backup_retention_period = var.rds_postgres_backup_retention_period
  rds_postgres_skip_final_snapshot     = var.rds_postgres_skip_final_snapshot
  rds_postgres_license_model           = var.rds_postgres_license_model
  rds_postgres_username                = var.rds_postgres_username
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
