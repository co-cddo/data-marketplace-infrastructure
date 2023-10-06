provider "aws" {
  region = var.region
}

module "vpcmodule"{
    source = "../modules/vpc"

    cidr_vpc = var.vpc_cidr
    private_subnets = var.private_subnets
    public_subnets = var.public_subnets
    env_name = var.dev_env_name
    project_code = var.project_code
    
    cluster_name = var.cluster_name
    cluster_version = var.cluster_version

}
module "dynamodb" {
    source = "../modules/dynamodb"
    env_name = var.dev_env_name
}

module "eks_cluster"{
    source = "../modules/eks"
    cluster_name = var.cluster_name
    cluster_version = var.cluster_version
    env_name = var.dev_env_name
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
    public_subnet_one_id = module.vpcmodule.public_subnets_output[0]
    public_subnet_two_id = module.vpcmodule.public_subnets_output[1]
    region = var.region
    app_namespace = var.app_namespace

}

module "load_balancer_dev" {

    source = "../modules/load-balancer"
    vpc_id = module.vpcmodule.vpc.id
    eks_cluster = module.eks_cluster.eks_cluster
    project_code = var.project_code
    env_name = var.dev_env_name
    eks_fargate_profile_kubesystem = module.eks_cluster.eks_fargate_profile_kubesystem
    # eks_fargate_profile_app = module.eks_cluster.eks_fargate_profile_app
    region = var.region
    cluster_name = var.cluster_name
    user_name = var.user_name
    openid_connector = module.eks_cluster.openid_connector
}

module "external_secrets_dev"{
    source = "../modules/external-secrets"
    eks_cluster = module.eks_cluster.eks_cluster
    cluster_name = var.cluster_name
    project_code = var.project_code
    iam_fargate = module.eks_cluster.iam_fargate
    openid_connector = module.eks_cluster.openid_connector
    env_name = var.dev_env_name
    region = var.region
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
    sa_name = "externalsecret-sa"
    sa_namespace = var.app_namespace
}

module "efs" {
    source = "../modules/efs"
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
    eks_cluster = module.eks_cluster.eks_cluster
    env_name = var.dev_env_name
}

module "app_params" {
    source  = "../modules/parameter-store"
    prefix = "/${var.project_code}/${var.env_name}/services/"
    securestring_parameters = [
        "API_ENDPOINT",
        "SSO_AUTH_URL",
        "SSO_CALLBACK_URL",
        "SSO_CLIENT_ID",
        "SSO_CLIENT_SECRET",
        "JWT_AUD",
        "JWKS_URL"
    ]
}
