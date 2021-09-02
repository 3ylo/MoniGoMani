#!/bin/bash

# === Description ======================================================================================================
#
# This file contains the installation procedure to get up and running with Freqtrade and the MoniGoMani HyperStrategy.
#
# === Requirements =====================================================================================================
#
#  - UNIX Distro, macOS, or a POSIX compliant WSL Distro (sh, bash, command, mktemp, pwd, rm, /dev/null)
#  - Python 3.8+
#  - Git
#  - Pip3 python package manager
#
# Windows Specific Notes:
#   This script has been made with the intention to run on UNIX systems and it makes use of UNIX command line tools..
#   However if you really have no other option, it should also be able to run under WSL (Windows Subsystem for Linux)!
#   - See for installation:       https://docs.microsoft.com/en-us/windows/wsl/install-win10
#   - Then change 'sh' to 'bash': https://unix.stackexchange.com/a/442517
#
# === Usage ============================================================================================================
#
#   /usr/bin/env sh <(curl -s "https://raw.githubusercontent.com/Rikj000/MoniGoMani/development/installer.sh")
#
# === Settings =========================================================================================================
INSTALL_FOLDER_NAME="freqtrade-mgm" # By default the folder will be created under the current working directory
MGM_REPO_URL="https://github.com/Rikj000/MoniGoMani.git"
MGM_BRANCH="development"
MGM_COMMIT=""
# ======================================================================================================================

usage() {

    cat << EOF

  Usage:
    /usr/bin/env sh installer.sh [options]

  Example:
    /usr/bin/env sh installer.sh --dir="./targetdir" --mgm_branch="feature/xyz" --mgm_commit="abcd1337"

  Optional options:
    -h, --help                    Show this help.

    --dir=<path>                  Path to directory to install Freqtrade with MoniGoMani.
                                  Will be created or overwritten when it's existing.

    --mgm_url=<url>               URL to Git repository. (eg. https://github.com/Rikj000/MoniGoMani.git)
    --mgm_branch=<branch>         Specific branch to checkout from Git repository. (eg. development)
    --mgm_commit=<commit hash>    Specific commit hash to checkout from Git repository.
                                  (Note: will skip --mgm_branch if set)

    --dev-break                   Break before launching MGM-Hurry

EOF

    exit 0
}

CURRENT_DIR=$(pwd)
INSTALL_DIR="$CURRENT_DIR/$INSTALL_FOLDER_NAME"

# ANSI text coloring
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[0;31m'
NOCOLOR='\033[0m'
CLOSE='\033[m'

# Loop through arguments and process them
DEV_BREAK="false"
for arg in "$@"
do
    case $arg in
        --dir=*)
        INSTALL_DIR="${arg#*=}"
        shift
        ;;
        --mgm_url=*)
        MGM_REPO_URL="${arg#*=}"
        shift
        ;;
        --mgm_branch=*)
        MGM_BRANCH="${arg#*=}"
        shift
        ;;
        --mgm_commit=*)
        MGM_COMMIT="${arg#*=}"
        shift
        ;;
        --dev-break)
        DEV_BREAK="true"
        shift
        ;;
        -h|--help)
        usage
        shift
        ;;
        *)
        echo ""
        echo -e "${RED}  🙉  installer.sh - Illegal argument(s) used!${CLOSE}"
        echo ""
        echo "  Please see the 'installer.sh --help' output below for the correct usage:"
        usage
        shift # Remove generic argument from processing
        ;;
    esac
done

##################

confirm() {
    local _prompt _default _response

    _prompt="Are you sure?"
    if [ "$1" ]; then _prompt="$1"; fi

    _prompt2="$_prompt [y/n]"
    if [ "$2" ]; then _prompt2="$_prompt $2"; fi

    # Loop forever until the user enters a valid response (Y/N or Yes/No).
    while true; do
        read -r -p "  $_prompt2

  " _response
        case "$_response" in
        [Yy][Ee][Ss]|[Yy]) # Yes or Y (case-insensitive).
            REPLY="0"
            return $REPLY
            ;;
        [Nn][Oo]|[Nn])  # No or N.
            REPLY="1"
            return $REPLY
            ;;
        [Hh])  # H or h. H stands for Half.
            REPLY="2"
            return $REPLY
            ;;
        *) # Anything else (including a blank) is invalid.
            ;;
        esac
    done
}

do_exit() {
    echo "      cancel."
    echo ""
    echo -e "${WHITE}  😽  KTHXBAI  ${CLOSE}"
    echo ""
    exit 1
}

trap do_exit SIGINT

echo ""
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo ""
echo -e "${WHITE}  ⛱️  Welcome aboard! Let's get started ...${CLOSE}"
echo ""
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo ""

echo ""
echo -e "${WHITE}  🚦  Requirements check${CLOSE}"
echo -e "${WHITE}  ======================${CLOSE}"
echo ""

# Ensure that python3 is installed
command -v python3 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  🙉  Python3 is not installed. Can't proceed. See: https://realpython.com/installing-python/${CLOSE}"
    exit 1
fi
echo -e "${GREEN}  ✅  Python3 is installed.${CLOSE}"

# Ensure that pip3 is installed
command -v pip3 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  🙉  Pip3 is not installed. Can't proceed. See: https://pypi.org/project/pip/${CLOSE}"
    exit 1
fi
echo -e "${GREEN}  ✅  Pip3 is installed.${CLOSE}"

# Ensure that python3-venv is installed
OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
if [ "$OS" == "\"Ubuntu\"" -o "$OS" == "\"Debian\"" ]; then
    VENV_PACKAGE_NAME="`readlink -f $(which python3)  | awk -F'/' '{print $NF}'`-venv"
    dpkg -s  $VENV_PACKAGE_NAME | grep "ok installed" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}  🙉  Python3-venv is not installed. Can't proceed. install it with: sudo apt-get install ${VENV_PACKAGE_NAME}${CLOSE}"
        exit 1
    fi
    echo -e "${GREEN}  ✅  Python3-venv is installed.${CLOSE}"
fi

# Ensure that git is installed
command -v git >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  🙉  Git is not installed. Can't proceed. See: https://gist.github.com/derhuerst/1b15ff4652a867391f03${CLOSE}"
    exit 1
fi
echo -e "${GREEN}  ✅  Git is installed.${CLOSE}"

# Ensure that cURL is installed
command -v curl >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  🙉  cURL is not installed. Can't proceed. See: https://www.tecmint.com/install-curl-in-linux/${CLOSE}"
    exit 1
fi

echo -e "${GREEN}  ✅  cURL is installed.${CLOSE}"

# Ensure that expect is installed
command -v expect >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  🙉  Expect is not installed. Can't proceed. See: https://core.tcl-lang.org/expect/index${CLOSE}"
    exit 1
fi

echo -e "${GREEN}  ✅  Expect is installed.${CLOSE}"

# Ensure that TA-Lib (C dependency package) is installed
command -v ta-lib-config >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  🙉  TA-Lib (C dependency package) is not installed. Can't proceed. See: https://github.com/mrjbq7/ta-lib#dependencies${CLOSE}"
    exit 1
fi
echo -e "${GREEN}  ✅  TA-Lib (C dependency package) is installed.${CLOSE}"


echo ""
confirm "👉  Are you ready to proceed?" "(y/n)"

if [ "$REPLY" == "1" ] # 1 = False, why shell why..
then
    do_exit
    exit 1
fi


echo ""
echo ""
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo -e "${WHITE}  ⚙️  Downloading required files...${CLOSE}"
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo ""

git clone -n "$MGM_REPO_URL" "$INSTALL_DIR/monigomani"

if [ "$MGM_COMMIT" != "" ]; then
    cd "$INSTALL_DIR/monigomani" && git checkout -b "detached_by_installer" "$MGM_COMMIT"
else
    cd "$INSTALL_DIR/monigomani" && git checkout "$MGM_BRANCH"
fi

if [ "$DEV_BREAK" == "true" ]; then
  echo ""
  confirm "👉  Are you ready to proceed?" "(y/n)"

  if [ "$REPLY" == "1" ] # 1 = False, why shell why..
  then
      do_exit
      exit 1
  fi
fi

echo ""
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo -e "${WHITE}  ⚙️  Installing dependency packages...${CLOSE}"
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo ""

cd "$INSTALL_DIR" && pip3 install -r ./monigomani/requirements-mgm.txt && python3 ./monigomani/mgm-hurry up

echo ""
echo ""
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo ""
echo -e "${CYAN}  🎉  You are all set! We hope you enjoy your ride.${CLOSE}"
echo ""
echo -e "${WHITE}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${CLOSE}"
echo ""
