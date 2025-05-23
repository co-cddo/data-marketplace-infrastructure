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

if [ -z "$_ENVNAME" ]; then
    echo "ERROR: No environment name provided. Usage: $0 <environment_name>"
    exit 1
fi

echo "--------------------------------------------"
echo "--- TOPDIR:        $TOPDIR"
echo "--- BASH VERSION:  $BASH_VERSION"
echo "--- BASH PATH:     $BASH_PATH"
echo "--------------------------------------------"

_ENVIRONMENTS=(${1})
_DATAFILENAME=vardata

for _ENV in "${_ENVIRONMENTS[@]}"; do
    echo "--------------------------------------------"
    echo "--- ENVIRONMENT:  $_ENV"
    echo "--------------------------------------------"
    _DATAFILE=${TOPDIR}/config/inputdata/${_ENV}/${_ENV}-${_DATAFILENAME}



    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~ CLEANING UP Leftovers From Previous Runs"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    rm -f ${_DATAFILE}

    echo "--- INFO: Getting new ${_DATAFILE}"

    aws ssm get-parameters \
    --name "/dm/${_ENV}/config-inputs" \
    --with-decryption \
    --query "Parameters[*].{Value:Value}" \
    --output text > ${_DATAFILE}

    EXIT_STATUS=$?
    if [ "$EXIT_STATUS" -ne "0" ]
    then
        echo "ERROR: Something went wrong with the aws command"
        echo
        continue
    fi

    _TEMPLATEFILES=$(ls -1 config/templates/${_ENV}/)
    _TFILEARRAY=($_TEMPLATEFILES)
    for _TFILE in "${_TFILEARRAY[@]}"; do

        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "~~ TFILE:  $_TFILE"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        source ${_DATAFILE}
        cfgtemplate="${TOPDIR}/config/templates/${_ENV}/${_TFILE}"
        outputfile="${TOPDIR}/config/output/${_ENV}/${_TFILE}"
        tmpfile=$(mktemp)
        $CP --attributes-only --preserve $cfgtemplate $tmpfile
        cat $cfgtemplate | ${ENVSUBST} > $tmpfile && mv $tmpfile $outputfile
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

        xaws ssm put-parameter \
        --name "/dm/${_ENV}/appsettings/${_IDTAG}" \
        --type SecureString \
        --value file://${outputfile} \
        --overwrite

        echo
    done
done
