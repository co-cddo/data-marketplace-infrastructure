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

ENVNAME=${1}

if [ -z "$ENVNAME" ]; then
    echo "ERROR: No environment name provided. Usage: $0 <environment_name>"
    exit 1
fi

echo "--------------------------------------------"
echo "--- TOPDIR:        $TOPDIR"
echo "--- BASH VERSION:  $BASH_VERSION"
echo "--- BASH PATH:     $BASH_PATH"
echo "---"
echo "--- ENVNAME:       $ENVNAME"
echo "--------------------------------------------"

