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
DESTROYOUTFILE=${PLANOUTDIR}/tfdestroyout.${DSTAMP}
INITLOG=${LOGDIR}/tf-init.${DSTAMP}.log
APPLYLOG=${LOGDIR}/tf-apply-${DSTAMP}.log
PLANLOG=${LOGDIR}/tf-plan-${DSTAMP}.log
DESTROYLOG=${LOGDIR}/tf-destroy-${DSTAMP}.log
GITCLONELOG=${LOGDIR}/git-clone-${DSTAMP}.log
GITCHECKOUTLOG=${LOGDIR}/git-checkout-${DSTAMP}.log
MYIP=$(ip addr show dev enX0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
MYTYPE=$(cat /etc/os-release | grep ^NAME | awk -F= '{print $2}' | sed 's/"//g')
REPODIR=data-marketplace-infrastructure

CURRENTCONTEXT=$(kubectl config current-context)

if [[ -z "$CURRENTCONTEXT" ]]; then
    echo "ERROR: Must provide CURRENTCONTEXT" 1>&2
    exit 1
fi

echo "CURRENTCONTEXT:  ${CURRENTCONTEXT}"

CONTEXTLOWERCASE=$(echo "${CONTEXT}" | tr '[:upper:]' '[:lower:]')
CURRENTCONTEXTEXTRACTED=$(echo "${CURRENTCONTEXT}" | awk -F: '{print $6}' | awk -F\/ '{print $2}' | awk -F\- '{print $2}')

if   [ "${CONTEXTLOWERCASE}" != "${CURRENTCONTEXTEXTRACTED}" ];then
    echo "ERROR: CONTEXT Mismatch with \"Pipeline\"  to \"Local\" compared" 1>&2
    exit 1
fi

REGION=$(echo   "${CURRENTCONTEXT}" | awk -F: '{print $4}')
AWSACCID=$(echo "${CURRENTCONTEXT}" | awk -F: '{print $5}')

case ${CONTEXT} in
  dev|Dev)
    KSCONTEXT="${CURRENTCONTEXT}"
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-sample-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-sample-base-initial"
    ENV=dev
    ;;
  tst|Tst|Test)
    KSCONTEXT="${CURRENTCONTEXT}"
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-sample-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-sample-base-initial"
    ENV=tst
    ;;
  stg|Stg|Stage)
    KSCONTEXT="${CURRENTCONTEXT}"
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-sample-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-sample-base-initial"
    ENV=stg
    ;;
  pro|Pro|Prod)
    KSCONTEXT="${CURRENTCONTEXT}"
    MSSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-mssql-prod-base-initial"
    PGSQL_SNAPSHOT="arn:aws:rds:${REGION}:${AWSACCID}:snapshot:dm-postgres-prod-base-initial"
    ENV=pro
    ;;
  *)
    echo "ERROR: unknown CONTEXT"
    echo "Expected one of Dev | Test | Stage | Prod"
    KSCONTEXT="unknown"
    exit 1
    ;;
esac

mkdir -p ${PLANOUTDIR} ${LOGDIR}

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "#~~ Processing Script"
echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "DATE/TIME  \"${DSTAMP}\""

echo "#~~ INFO: ENVIRONMENT: ${1} | TFACTION: ${2} GITHUBJOB: ${3}"

echo "#~~ INFO: Setting Kubernetes Context to ${CONTEXT}"
kubectl config use-context ${KSCONTEXT}

cd ${BASEDIR} && rm -fR ./${REPODIR}
echo "#~~ INFO: git clone repo"
cd ${BASEDIR} && git clone --progress git@github.com:co-cddo/${REPODIR}.git       2> ${GITCLONELOG}
echo "#~~ INFO: git clone repo exitcode $?"
cd  ${BASEDIR}/${REPODIR} && git checkout --progress feature/jp-infraappconfig    2> ${GITCHECKOUTLOG}
echo "#~~ INFO: git checkout branch exitcode $?"

if   [ "${TFACTION}" == "init+plan" ] && [ "${GITHUBJOBNAME}" == "TerraformInitPlan" ]; then
    echo "#~~ INFO: |1| ENV: ${ENV} Running terraform init"
    cd ${BASEDIR}/${REPODIR}/${ENV}/ && \
    terraform init -no-color > ${INITLOG}
    echo "#~~ INFO: terraform init exitcode $?"

    echo "#~~ INFO:  ENV: ${ENV} Running terraform plan"
    cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
    terraform plan -no-color -out=${PLANOUTFILE} \
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

elif [ "${TFACTION}" == "init+plan+apply" ] && ( [ "${GITHUBJOBNAME}" == "TerraformInitPlan" ] || [ "${GITHUBJOBNAME}" == "TerraformApply" ] ); then
    echo "#~~ INFO: |2| ENV: ${ENV} Running terraform init"
    cd ${BASEDIR}/${REPODIR}/${ENV}/ && \
    terraform init -no-color > ${INITLOG}
    echo "#~~ INFO:  ENV: ${ENV} terraform init exitcode $?"

    echo "#~~ INFO:  ENV: ${ENV} Running terraform plan"
    cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
    terraform plan -no-color -out=${PLANOUTFILE} \
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

    echo "#~~ INFO:  ENV: ${ENV} Running terraform apply"
    cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
    terraform apply -no-color -out=${APPLYOUTFILE} \
    -var rds_mssql_snapshot_identifier="${MSSQL_SNAPSHOT}" \
    -var rds_postgres_snapshot_identifier="${PGSQL_SNAPSHOT}" > ${APPLYLOG}
    echo "#~~ INFO:  ENV: ${ENV} terraform apply exitcode $?"

elif [ "${TFACTION}" == "approval+destroy" ] && [ "${GITHUBJOBNAME}" == "TerraformDestroy" ]; then
    echo "#~~ INFO: |3| ENV: ${ENV} Running terraform destroy"
    cd ${BASEDIR}/${REPODIR}/${ENV}/  && \
    terraform destroy -no-color -out=${DESTROYOUTFILE} \
    -var rds_mssql_snapshot_identifier="${MSSQL_SNAPSHOT}" \
    -var rds_postgres_snapshot_identifier="${PGSQL_SNAPSHOT}" > ${DESTROYLOG}
    echo "#~~ INFO:  ENV: ${ENV} terraform destroy exitcode $?"

else
        echo "Error: Unknown Option, Exiting"
        exit 1
fi

echo "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
