#! /usr/bin/bash

DSTAMP=$(/bin/date +"%Y%m%d%H%M%S")

if [[ $# -ne 3 ]]; then
    echo "Incorrect number of parameters" >&2
    exit 2
fi

CONTEXT=${1}
TFACTION=${2}
GITHUBJOBNAME=${3}
BASEDIR=/home/ssm-user/src
APPLYOUTDIR=${BASEDIR}/out
PLANOUTDIR=${BASEDIR}/out
DESTROYOUTDIR=${BASEDIR}/out
LOGDIR=${BASEDIR}/log
APPLYOUTFILE=${PLANOUTDIR}/tfapplyout.${DSTAMP}
PLANOUTFILE=${PLANOUTDIR}/tfplanout.${DSTAMP}
PLANOUTFILECURRENT=${PLANOUTDIR}/tfplanout.CURRENT
DESTROYOUTFILE=${PLANOUTDIR}/tfdestroyout.${DSTAMP}
INITLOG=${LOGDIR}/tf-init.${DSTAMP}.log
APPLYLOG=${LOGDIR}/tf-apply-${DSTAMP}.log
PLANLOG=${LOGDIR}/tf-plan-${DSTAMP}.log
DESTROYLOG=${LOGDIR}/tf-destroy-${DSTAMP}.log
GITCLONELOG=${LOGDIR}/git-clone-${DSTAMP}.log
GITCHECKOUTLOG=${LOGDIR}/git-checkout-${DSTAMP}.log
GITBRANCH="feature/jp-gitactions"
S3BUCKET="jpbackupbucket20250502"
MYIP=$(ip addr show dev enX0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
MYTYPE=$(cat /etc/os-release | grep ^NAME | awk -F= '{print $2}' | sed 's/"//g')
REPODIR=data-marketplace-infrastructure
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
AWSACCID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "${REGION}" ]] || [[ -z "${AWSACCID}" ]]; then
    echo "ERROR: Unable to determine AWS Region or Account ID" >&2
    exit 1
fi
CONTEXTLOWERCASE=$(echo "${CONTEXT}" | tr '[:upper:]' '[:lower:]')
CURRENTCONTEXT=$(kubectl config current-context)

    echo "INFO: Creating a new CURRENTCONTEXT"
    aws eks update-kubeconfig --name dm-${CONTEXTLOWERCASE}-eks-cluster --region ${REGION}
    kubectl config use-context "arn:aws:eks:${REGION}:${AWSACCID}:cluster/dm-${CONTEXTLOWERCASE}-eks-cluster"
    CURRENTCONTEXT=$(kubectl config current-context)

echo "CURRENTCONTEXT:  ${CURRENTCONTEXT}"

case ${CONTEXT} in
  dev|Dev)
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-sample-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-sample-base-initial"
    ENV=dev
    ;;
  tst|Tst|Test)
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-sample-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-sample-base-initial"
    ENV=tst
    ;;
  stg|Stg|Stage)
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-sample-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-sample-base-initial"
    ENV=stg
    ;;
  pro|Pro|Prod)
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-prod-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-prod-base-initial"
    ENV=pro
    ;;
  *)
    echo "ERROR: unknown CONTEXT"
    echo "Expected one of Dev | Test | Stage | Prod"
    exit 1
    ;;
esac

mkdir -p ${PLANOUTDIR} ${LOGDIR}

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "#~~ Processing Script"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "DATE/TIME  \"${DSTAMP}\""

echo "#~~ INFO: ENVIRONMENT: ${1} | TFACTION: ${2} GITHUBJOB: ${3}"
echo "#~~ INFO: CURRENTCONTEXT: ${CURRENTCONTEXT}"
echo "#~~ INFO: REGION:         ${REGION}"
echo "#~~ INFO: AWSACCID:       ${AWSACCID}"

if   [ "${GITHUBJOBNAME}" != "TerraformApply" ]; then
    cd ${BASEDIR} && rm -fR ./${REPODIR}
    echo "#~~ INFO: git clone repo"
    cd ${BASEDIR} && git clone --progress git@github.com:co-cddo/${REPODIR}.git       2> ${GITCLONELOG}
    echo "#~~ INFO: git clone repo exitcode $?"
    cd  ${BASEDIR}/${REPODIR} && git checkout --progress ${GITBRANCH}                 2> ${GITCHECKOUTLOG}
    echo "#~~ INFO: git checkout branch exitcode $?"
fi

if   [ "${TFACTION}" == "init+plan" ] && [ "${GITHUBJOBNAME}" == "TerraformInitPlanOnly" ]; then
    echo "#~~ INFO: |1| ENV: ${ENV} Running terraform init"
    cd ${BASEDIR}/${REPODIR}/${ENV}/ && \
    terraform init -no-color > ${INITLOG}
    echo "#~~ INFO: terraform init exitcode $?"

    echo "#~~ INFO:  ENV: ${ENV} Running terraform plan"
    cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
    terraform plan -no-color -input=false -out=${PLANOUTFILE} \
    -var rds_mssql_snapshot_identifier="${MSSQL_SNAPSHOT}" \
    -var rds_postgres_snapshot_identifier="${PGSQL_SNAPSHOT}" > ${PLANLOG}
    echo "#~~ INFO:  ENV: ${ENV} terraform plan exitcode $?"
    echo -e "#~~ INFO: Review the below terraform plan output summary"
    echo -e "-----"
    if   [ "$(terraform show -no-color ${PLANOUTFILE}  2>&1 | grep -c '^Plan:')" -ge 1 ]; then
              terraform show -no-color ${PLANOUTFILE}  2>&1 | grep    '^Plan:'
    elif [ "$(terraform show -no-color ${PLANOUTFILE}  2>&1 | grep -c '^No changes')" -ge 1 ]; then
              terraform show -no-color ${PLANOUTFILE}  2>&1 | grep    '^No changes'
    else
        echo "Error: Exiting"
        exit 1
    fi
    echo -e "-----"
    echo "#~~ INFO:  Uploading PLANOUTFILE to S3"
    terraform show -no-color ${PLANOUTFILE}  2>&1 > ${PLANOUTFILE}.txt
    aws s3 cp ${PLANOUTFILE}.txt s3://${S3BUCKET}/PLANOUTFILE.txt


elif [ "${TFACTION}" == "init+plan+apply" ] && ( [ "${GITHUBJOBNAME}" == "TerraformInitPlan" ] || [ "${GITHUBJOBNAME}" == "TerraformApply" ] ); then

    if [ "${GITHUBJOBNAME}" == "TerraformInitPlan" ]; then
        echo "#~~ INFO: |2| ENV: ${ENV} Running terraform init"
        cd ${BASEDIR}/${REPODIR}/${ENV}/ && \
        terraform init -no-color > ${INITLOG}
        echo "#~~ INFO:  ENV: ${ENV} terraform init exitcode $?"

        echo "#~~ INFO:  ENV: ${ENV} Running terraform plan"
        cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
        terraform plan -no-color -input=false -out=${PLANOUTFILE} \
        -var rds_mssql_snapshot_identifier="${MSSQL_SNAPSHOT}" \
        -var rds_postgres_snapshot_identifier="${PGSQL_SNAPSHOT}" > ${PLANLOG}
        echo "#~~ INFO:  ENV: ${ENV} terraform plan exitcode $?"
        echo -e "#~~ INFO:  ENV: ${ENV} Review the below terraform plan output summary"
        echo -e "-----"
        if   [ "$(terraform show -no-color ${PLANOUTFILE}  2>&1 | grep -c '^Plan:')" -ge 1 ]; then
                  terraform show -no-color ${PLANOUTFILE}  2>&1 | grep    '^Plan:'
        elif [ "$(terraform show -no-color ${PLANOUTFILE}  2>&1 | grep -c '^No changes')" -ge 1 ]; then
                  terraform show -no-color ${PLANOUTFILE}  2>&1 | grep    '^No changes'
        else
            echo "Error: Exiting"
            exit 1
        fi
        echo -e "-----"
        cp ${PLANOUTFILE} ${PLANOUTFILECURRENT}
        echo "#~~ INFO:  Uploading PLANOUTFILE to S3"
        terraform show -no-color ${PLANOUTFILE}  2>&1 > ${PLANOUTFILE}.txt
        aws s3 cp ${PLANOUTFILE}.txt s3://${S3BUCKET}/PLANOUTFILE.txt
    fi

    if [ "${GITHUBJOBNAME}" == "TerraformApply" ]; then
        echo "#~~ INFO:  ENV: ${ENV} Running terraform apply"
        cd ${BASEDIR}/${REPODIR}/${ENV}/ && \
        terraform apply -no-color -auto-approve \
        -var rds_mssql_snapshot_identifier="${MSSQL_SNAPSHOT}" \
        -var rds_postgres_snapshot_identifier="${PGSQL_SNAPSHOT}"  \
        ${PLANOUTFILECURRENT} 2>&1 > ${APPLYLOG}.txt
        echo "#~~ INFO:  ENV: ${ENV} terraform apply exitcode $?"
        echo "#~~ INFO:  Uploading APPLYLOG to S3"
        aws s3 cp ${APPLYLOG}.txt s3://${S3BUCKET}/APPLYLOG.txt
    fi

elif [ "${TFACTION}" == "approval+destroy" ] && [ "${GITHUBJOBNAME}" == "TerraformDestroy" ]; then
    echo "#~~ INFO: |3| ENV: ${ENV} Running terraform destroy"
    cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
    terraform destroy -no-color -auto-approve  2>&1 > ${DESTROYLOG}.txt
    echo "#~~ INFO:  ENV: ${ENV} terraform destroy exitcode $?"
    echo "#~~ INFO:  Uploading DESTROYLOG to S3"
    aws s3 cp ${DESTROYLOG}.txt s3://${S3BUCKET}/DESTROYLOG.txt

else
        echo "Error: Unknown Option, Exiting"
        exit 1
fi

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

