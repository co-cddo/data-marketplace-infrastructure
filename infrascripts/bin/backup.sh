#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        CP=/usr/bin/cp
        ENVSUBST=/usr/bin/envsubst
        GREP=/usr/bin/grep
        FIND=/usr/bin/find
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX: You need
        # brew install coreutils
        # brew install findutils
        # brew install gettext
        # envsubst is included in gettext package
        CP=/opt/homebrew/bin/gcp
        ENVSUBST=/opt/homebrew/bin/envsubst
        GREP=/opt/homebrew/bin/ggrep
        FIND=/opt/homebrew/bin/gfind
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        echo "OSTYPE:   $OSTYPE"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        echo "OSTYPE:   $OSTYPE"
else
        echo "OSTYPE:   UNKNOWN"
fi

DSTAMP=$(/bin/date +%Y%m%d%H%M%S)

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

_ENVIRONMENTS=(${_ENVNAME})

for _ENV in "${_ENVIRONMENTS[@]}"; do
  echo "--------------------------------------------"
  echo "--- ENVIRONMENT:  $_ENV"
  echo "--------------------------------------------"

  echo "INFO: Removing previous LOCAL json files"
  cd ${TOPDIR}/output/ && ${FIND} . -maxdepth 0 -name "*.json" -type f -delete

  echo "INFO: Creating dir structre output/${_ENV}"
  echo "INFO: mkdir -p ${TOPDIR}/output/${_ENV}"
              mkdir -p ${TOPDIR}/output/${_ENV}

   _CONFFILEARRAY=(
  /dm/${_ENV}/appsettings/api
  /dm/${_ENV}/appsettings/catalogue
  /dm/${_ENV}/appsettings/datashare
  /dm/${_ENV}/appsettings/ui
  /dm/${_ENV}/appsettings/users
  )

  for _CFILE in "${_CONFFILEARRAY[@]}"
  do
      _IDTAG=`echo ${_CFILE} | awk -F\/ '{print $5}'`

      echo "--------------------------------------------"
      echo "--- TFILE:  ${_CFILE}"
      echo "--- IDTAG:  ${_IDTAG}"
      echo "--- SAVE:   output/${_ENV}/${_ENV}-dm-fast-${_IDTAG}-config.json"
      echo "--------------------------------------------"

      aws ssm get-parameters \
      --name "/dm/${_ENV}/appsettings/${_IDTAG}" \
      --with-decryption \
      --query "Parameters[*].{Value:Value}" \
      --output text \
      | tee  "${TOPDIR}/output/${_ENV}/${_ENV}-dm-fast-${_IDTAG}-config.json"
  done
done

echo "--------------------------------------------"
echo "--- INFO: Tree structre of output/${_ENV}"
echo "--------------------------------------------"
tree ${TOPDIR}/

