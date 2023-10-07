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
echo -e "${red} DO NOT FORGET TO UPDATE CNAME !${clear}"

ACTION=${1}
EXT_SECRET_ROLE=arn:aws:iam::${ACCOUNT}:role/dm-${ENV_NAME}-role-eks-externalsecrets

 
mkdir tmp
WORKDIR=tmp
cp templates/* $WORKDIR
cd $WORKDIR

sed -i "s|{{ROLE_ARN}}|${EXT_SECRET_ROLE}|g" 02_serviceaccount.yml
sed -i "s/eu-west-2/${REGION}/g" 03_externalsecret.yml
sed -i "s/{{EFS_FSID}}/${EFS_FSID}/g" 03_efs.yml

IMG_FRONTEND=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-frontend:ver${FRONTEND_VERSION}
IMG_API=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-backend-api:ver${API_VERSION}
IMG_FUSEKI=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/dm-backend-fuseki:ver${FUSEKI_VERSION}

sed -i "s|{{IMG}}|${IMG_FRONTEND}|g" 04_deployment_frontend.yml
sed -i "s|{{IMG}}|${IMG_API}|g" 04_deployment_api.yml
sed -i "s|{{IMG}}|${IMG_FUSEKI}|g" 04_deployment_fuseki.yml

sed -i "s|{{ENV_NAME}}|${ENV_NAME}|g" 06_ingress.yml
sed -i "s|CERTIFICATEARN|${CERTIFICATEARN}|g" 06_ingress.yml
sed -i "s|USERPOOLARN|${USERPOOLARN}|g" 06_ingress.yml
sed -i "s|USERPOOLCLIENTID|${USERPOOLCLIENTID}|g" 06_ingress.yml
sed -i "s|USERPOOLDOMAIN|${USERPOOLDOMAIN}|g" 06_ingress.yml

if [[ ${ACTION} == "install" ]]; then

  kubectl apply -f 01_namespace.yml
  kubectl apply -f 02_serviceaccount.yml
  kubectl apply -f 03_externalsecret.yml
  kubectl apply -f 03_efs.yml

  kubectl apply -f 04_deployment_fuseki.yml
  kubectl apply -f 04_deployment_api.yml
  kubectl apply -f 04_deployment_frontend.yml


  kubectl apply -f 05_service.yml

  kubectl apply -f 06_ingress.yml

fi

if [[ ${ACTION} == "uninstall" ]]; then

  kubectl delete -f 03_efs.yml

  kubectl delete ns app
fi

if [[ ${ACTION} == "update" ]]; then
  echo "updating"
  echo "updated"
fi

cd ..
rm -rf $WORKDIR
