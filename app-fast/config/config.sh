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

    _TEMPLATEDIR=${TOPDIR}/config/templates
    _OUTPUTDIR=${TOPDIR}/config/output
    _DATAFILEDIR=${TOPDIR}/config/inputdata
    _DATAFILECOMBINEDNAME=${_ENV}-${_DATAFILENAME}
    _DATAFILE=${_DATAFILEDIR}/${_DATAFILECOMBINEDNAME}

    mkdir -p  ${_TEMPLATEDIR} ${_OUTPUTDIR} ${_DATAFILEDIR}

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~ CLEANING UP Leftovers From Previous Runs (if any)"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    rm -f ${_DATAFILE}

    echo "--- INFO: Getting Master Data File for Environment: ${_ENV}"

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

    _TEMPLATEFILES=$(ls -1 ${_TEMPLATEDIR}/)
    _TFILEARRAY=($_TEMPLATEFILES)
    for _TFILE in "${_TFILEARRAY[@]}"; do

        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "~~ TFILE:  $_TFILE"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        source ${_DATAFILE}
        cfgtemplate="${_TEMPLATEDIR}/${_TFILE}"
        outputfile="${_OUTPUTDIR}/${_ENV}-${_TFILE}"
        tmpfile=$(mktemp)
        $CP --attributes-only --preserve $cfgtemplate $tmpfile
        cat $cfgtemplate | ${ENVSUBST} > $tmpfile && mv $tmpfile $outputfile
        echo "------------------------"
        echo "--- RESULT:  output/$(basename $outputfile)"
        echo "------------------------"
        cat $outputfile

        _IDTAG=`echo ${_TFILE} | awk -F\- '{print $1}'`
        _UPLDFILENAME="/dm/${_ENV}/appsettings/${_IDTAG}"

        echo "--------------------------------------------"
        echo "--- TFILE          :  $_TFILE"
        echo "--- IDTAG          :  ${_IDTAG}"
        echo "--- UPLOADING FROM :  output/$(basename $outputfile)"
        echo "--- UPLOADING AS   :  ${_UPLDFILENAME}"
        echo "--------------------------------------------"

        echo "aws ssm put-parameter \\"
        echo "--name "${_UPLDFILENAME}" \\"
        echo "--type SecureString \\"
        echo "--value file://${outputfile} \\"
        echo "--overwrite"

        aws ssm put-parameter \
        --name "${_UPLDFILENAME}" \
        --type SecureString \
        --value file://${outputfile} \
        --overwrite

        echo
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "~~ CLEANING UP"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        rm -f ${outputfile}
        rm -f ${tmpfile}
    done
    rm -f ${_DATAFILE}
done
