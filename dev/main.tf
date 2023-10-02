
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
    //region = var.region
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

}

module "load_balancer_dev" {
    resource "null_resource" "kubeconfig"{
        provisioner "local-exec" {
        command =  <<EOH
        aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}
        export KUBE_CONFIG_PATH=/home/ec2-user/.kube/config
        EOH
    }
    }
    source = "../modules/load-balancer-dev"
    vpc_id = module.vpcmodule.vpc.id
    eks_cluster = module.eks_cluster.eks_cluster
    env_name = var.dev_env_name
    eks_fargate_profile_kubesystem = module.eks_cluster.eks_fargate_profile_kubesystem
}
/*
module "external_secrets_dev"{
    source = "../modules/external-secrets-dev"
    eks_cluster = module.eks_cluster.eks_cluster
    cluster_name = var.cluster_name
    iam_fargate = module.eks_cluster.iam_fargate
    openid_connector = module.load_balancer_dev.openid_connector
    env_name = var.dev_env_name
    region = var.region
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
}
*/
module "efs" {
    source = "../modules/efs"
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0]
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1]
    eks_cluster = module.eks_cluster.eks_cluster
    env_name = var.dev_env_name
}

module "app_params" {
    source  = "../modules/parameter-store"
    prefix = "/dm/dev/data-marketplace/gen/"
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
