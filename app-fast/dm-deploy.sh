#!/bin/bash
set -e

set -o allexport
source ./.env 
set +o allexport



if [ $# -lt 1 ]
  then
    echo "Usage: sh dm-services.sh <install|update|uninstall>"
    exit 1
fi

# IMPORTANT: PLEASE CHECK THE .env FILE: REQUIRED PARAMETERS

green='\033[0;32m'
red='\033[0;31m'
# Clear the color after that
clear='\033[0m'

echo -e "${green}IMPORTANT: PLEASE CHECK THE .env FILE: REQUIRED PARAMETERS!${clear}"
echo -e "${green} EFS ID, CERT ARN, COGNITO CLIENT ID !${clear}"
echo -e "${green} DO NOT FORGET TO UPDATE CNAME !${clear}"

echo -e "${red} DOUBLE CHECK KUBE CONFIG! YOU HAVE TO CONNECT THE ${ENV_NAME}. TYPE YES IF YOU ARE SURE! ${clear}"
read userapprove
if [[ ${userapprove} != "YES" ]]; then
exit
fi


ACTION=${1}
EXT_SECRET_ROLE=arn:aws:iam::${ACCOUNT}:role/dm-${ENV_NAME}-role-eks-externalsecrets
AWS_GENERIC_ROLE=arn:aws:iam::${ACCOUNT}:role/dm-${ENV_NAME}-role-eks-aws-generic-serviceaccount


kubectl config use-context arn:aws:eks:${REGION}:${ACCOUNT}:cluster/dm-${ENV_NAME}-eks-cluster



mkdir tmp
WORKDIR=tmp
cp templates/* $WORKDIR
cd $WORKDIR

sed -i "s|{{ROLE_ARN}}|${EXT_SECRET_ROLE}|g" 02_serviceaccount.yml
sed -i "s|{{ROLE_ARN_AWS_GENERIC}}|${AWS_GENERIC_ROLE}|g" 02_serviceaccount.yml
sed -i "s/eu-west-2/${REGION}/g" 03_externalsecret.yml
sed -i "s|{{ENV_NAME}}|${ENV_NAME}|g" 03_externalsecret.yml

IMG_UI=${ECR_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-fast-${ENV_NAME}:ui-${UI_VERSION}
IMG_API=${ECR_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-fast-${ENV_NAME}:api-${API_VERSION}
IMG_USERS=${ECR_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-fast-${ENV_NAME}:users-${USERS_VERSION}
IMG_DATASHARE=${ECR_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-fast-${ENV_NAME}:datashare-${DATASHARE_VERSION}
IMG_CATALOGUE=${ECR_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-fast-${ENV_NAME}:catalogue-${CATALOGUE_VERSION}

sed -i "s|{{IMG}}|${IMG_UI}|g" 04_deployment_ui.yml
sed -i "s|{{IMG}}|${IMG_API}|g" 04_deployment_api.yml
sed -i "s|{{IMG}}|${IMG_USERS}|g" 04_deployment_users.yml
sed -i "s|{{IMG}}|${IMG_DATASHARE}|g" 04_deployment_datashare.yml
sed -i "s|{{IMG}}|${IMG_CATALOGUE}|g" 04_deployment_catalogue.yml

sed -i "s|{{ENV_FULLNAME}}|${ENV_FULLNAME}|g" 04_deployment_ui.yml
sed -i "s|{{ENV_FULLNAME}}|${ENV_FULLNAME}|g" 04_deployment_api.yml
sed -i "s|{{ENV_FULLNAME}}|${ENV_FULLNAME}|g" 04_deployment_users.yml
sed -i "s|{{ENV_FULLNAME}}|${ENV_FULLNAME}|g" 04_deployment_datashare.yml
# NO ENV_FULLNAME FOR CATALOGUE, IT TAKES IT FROM CONF.

sed -i "s|{{ENV_NAME}}|${ENV_NAME}|g" 06_ingress.yml
sed -i "s|CERTIFICATEARN|${CERTIFICATEARN}|g" 06_ingress.yml

sed -i "s|{{ENV_NAME}}|${ENV_NAME}|g" 00_logging_configmap.yml

if [[ ${ACTION} == "install" ]]; then

  kubectl apply -f 00_logging_ns.yml
  kubectl apply -f 00_logging_configmap.yml

  kubectl apply -f 01_namespace.yml
  kubectl apply -f 02_serviceaccount.yml
  kubectl apply -f 03_externalsecret.yml

  kubectl apply -f 04_deployment_ui.yml
  kubectl apply -f 04_deployment_api.yml
  kubectl apply -f 04_deployment_users.yml
  kubectl apply -f 04_deployment_datashare.yml
  kubectl apply -f 04_deployment_catalogue.yml

  kubectl apply -f 05_service.yml

  kubectl apply -f 06_ingress.yml

fi

if [[ ${ACTION} == "uninstall" ]]; then

  kubectl delete ns app
  kubectl delete -f 00_logging_ns.yml
fi

if [[ ${ACTION} == "update" ]]; then
  echo "updating"
  
#  kubectl apply -f 03_externalsecret.yml
  
  kubectl apply -f 04_deployment_ui.yml
  kubectl apply -f 04_deployment_api.yml
  kubectl apply -f 04_deployment_users.yml
  kubectl apply -f 04_deployment_datashare.yml
  kubectl apply -f 04_deployment_catalogue.yml
  echo "updated"


fi

cd ..
rm -rf $WORKDIR
echo -e "${green} DO NOT FORGET TO UPDATE CNAME !${clear}"
