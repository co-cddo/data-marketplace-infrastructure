#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        CP=/usr/bin/cp
        ENVSUBST=/usr/bin/envsubst
        GREP=/usr/bin/grep
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX: You need brew installe coreutils
        # brew install coreutils
        CP=/opt/homebrew/bin/gcp
        ENVSUBST=/opt/homebrew/bin/envsubst
        GREP=/opt/homebrew/bin/ggrep
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        echo "OSTYPE:   $OSTYPE"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        echo "OSTYPE:   $OSTYPE"
else
        echo "OSTYPE:   UNKNOWN"
fi

TOPDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BASH_PATH=${BASH_PATH:-$(which bash)}
BASH_VERSION=${BASH_VERSION:-$(bash --version | head -n 1 | cut -d ' ' -f 4)}
BASH_MAJOR_VERSION=${BASH_VERSION%%.*}

if [ "$BASH_MAJOR_VERSION" -lt 4 ]; then
    echo "ERROR: Bash version 4 or higher is required. Please update your Bash version."
    echo "       Or for MacOS install GNU Bash as \"brew install bash\" and set the path to it in your .bash_profile"
    exit 1
fi

_ENVNAME=${1}
_BUCKETNAME=${BUCKETNAME:-xxxxxxxxxxxxxxxxxxxxxx}

if [ -z "$_ENVNAME" ]; then
    echo "ERROR: No environment name provided. Usage: $0 <environment_name>"
    exit 1
fi

echo "--------------------------------------------"
echo "--- TOPDIR:        $TOPDIR"
echo "--- BASH VERSION:  $BASH_VERSION"
echo "--- BASH PATH:     $BASH_PATH"
echo "--------------------------------------------"

_DATAFILENAME=vardata
_ENVIRONMENTS=(${1})

for _ENV in "${_ENVIRONMENTS[@]}"; do
    echo "--------------------------------------------"
    echo "--- ENVIRONMENT:  $_ENV"
    echo "--------------------------------------------"
    _S3DATAFILELOCATION=$_BUCKETNAME/deployment/config/templates/${_ENV}/${_DATAFILENAME}
    _DATAFILES=${TOPDIR}/inputdata/${_ENV}-${_DATAFILENAME}

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~ CLENING UP (LOCAL FILES)"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    rm -f ${TOPDIR}/inputdata/*
    rm -f ${TOPDIR}/output/*
    rm -f ${TOPDIR}/templates/*
    echo "INFO: Getting  new vardata file"
    aws s3 cp  s3://${_S3DATAFILELOCATION}  ${TOPDIR}/inputdata/${_ENV}-${_DATAFILENAME}
    EXIT_STATUS=$?
    if [ "$EXIT_STATUS" -ne "0" ]
    then
        echo "ERROR: Something went wrong with the S3 copy command"
        echo
        continue
    fi

    echo "--------------------------------------------"
    echo "--- ${TOPDIR}/inputdata/"
    echo "--------------------------------------------"
      ls -l ${TOPDIR}/inputdata/

      if [ -z "$_DATAFILES" ]; then
        echo "No data files found in inputdata/$_ENV/"
        echo
        continue
      else
        echo "$_ENV DATAFILES:    $(basename $_DATAFILES)"
        source $_DATAFILES
        _TEMPLATESDIR="deployment/config/templates/${_ENV}"
        _TEMPLATEFILES=$(aws s3api list-objects \
        --bucket "${_BUCKETNAME}" \
        --prefix "${_TEMPLATESDIR}" \
        --query "Contents[].{Key: Key}" \
        --output text | \
        grep -v "${_DATAFILENAME}" | \
        grep -v '/$' | \
        xargs -L 1 basename)

        echo "--------------------------------------------"
        echo "-- TEMPLATE FILES AT REMOTE S3"
        printf '%s\n' "${_TEMPLATEFILES}"
        echo "--------------------------------------------"

        if [ -z "$_TEMPLATEFILES" ]; then
          echo "ERROR: 555 No template files found in  s3:// templates/$_ENV/"
          echo
          continue
        else
          _TFILEARRAY=($_TEMPLATEFILES)

          for _TFILE in "${_TFILEARRAY[@]}"; do

              echo "--------------------------------------------"
              echo "--- TFILE:  $_TFILE"
              echo "--------------------------------------------"
              echo "INFO: Removing old template file $_TFILE"
              rm -f ${TOPDIR}/templates/${_TFILE}
              echo "INFO: Getting  new template file $_TFILE"
              aws s3 cp s3://${_BUCKETNAME}/${_TEMPLATESDIR}/$_TFILE ${TOPDIR}/templates/${_TFILE}
                EXIT_STATUS=$?
                if [ "$EXIT_STATUS" -ne "0" ]
                then
                    echo "ERROR: 666 No template files found in templates/$_ENV/"
                    echo
                    continue
                else
                  originalfile="${TOPDIR}/templates/${_TFILE}"
                  outputfile="${TOPDIR}/output/${_TFILE}"
                  tmpfile=$(mktemp)
                  $CP --attributes-only --preserve $originalfile $tmpfile
                  cat $originalfile | ${ENVSUBST} > $tmpfile && mv $tmpfile $outputfile
                  echo "------------------------"
                  echo "--- RESULT:  output/$(basename $outputfile)"
                  echo "------------------------"
                  cat $outputfile

                  _IDTAG=`echo ${_TFILE} | awk -F\- '{print $4}'`

                  echo "--------------------------------------------"
                  echo "--- TFILE           :  $_TFILE"
                  echo "--- IDTAG           :  ${_IDTAG}"
                  echo "--- UPLOADING PSTORE:  output/$(basename $outputfile)"
                  echo "--- UPLOADING AS    :  ${_ENV}-dm-fast-${_IDTAG}-config.json"
                  echo "--------------------------------------------"

                  echo "aws ssm put-parameter \\"
                  echo "--name "/dm/${_ENV}/appsettings/${_IDTAG}" \\"
                  echo "--type SecureString \\"
                  echo "--value file://${outputfile} \\"
                  echo "--overwrite"

                  aws ssm put-parameter \
                  --name "/dm/${_ENV}/appsettings/${_IDTAG}" \
                  --type SecureString \
                  --value file://${outputfile} \
                  --overwrite

                  echo
                fi
          done
        fi
      fi
done

