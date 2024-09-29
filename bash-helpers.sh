#!/usr/bin/env bash

# TODO: get more ideas from: https://github.com/martinburger/bash-common-helpers

blue='\033[0;34m'
nocolor='\033[0m'
red="\033[0;31m"
green="\033[0;32m"

# https://github.com/martinburger/bash-common-helpers/blob/master/bash-common-helpers.sh
function exit_on_error_and_undefined() {
    # Will exit script if we would use an uninitialised variable:
    set -o nounset
    # Will exit script when a simple command (not a control structure) fails:
    set -o errexit
}

function test_dep() {
    command -v "$1" >/dev/null 2>&1
}
function install_if_not_installed() {
    for i in "$@"; do
        test_dep "$i" || sudo apt install -y "$i"
    done
}

function info() {
    echo -e "${blue}------------------------------------------------------------"
    echo -e "$*"
    echo -e "${nocolor}"
}
function success() {
    echo -e "${green}✅ $*${nocolor}"
}
function die() {
    if [ "$1" -ge 1 ]; then
        echo >&2 -e "${red}❌ ${*:2}${nocolor}"

        exit "$1"
    fi
}

function json_message() {
    if command -v jq >/dev/null 2>&1; then
        filter=${3:-tostring}
        jq -n \
            --arg message "$1" \
            --argjson success "[$2]" \
            '{"success":$success[0],"message":$message|'"$filter"'}'
    else
        echo "'jq' is not installed" >&2
    fi
}

function json_error() {
    json_message "$1" false "$2"
    exit 1
}

function json_success() {
    json_message "$1" true "$2"
}

#
# USER INTERACTION -------------------------------------------------------------
#

# cmn_ask_to_continue message
#
# Asks the user - using the given message - to either hit 'y/Y' to continue or
# 'n/N' to cancel the script.
#
# Example:
# cmn_ask_to_continue "Do you want to delete the given file?"
#
# On yes (y/Y), the function just returns; on no (n/N), it prints a confirmative
# message to the screen and exits with return code 1 by calling `cmn_die`.
# https://github.com/martinburger/bash-common-helpers/blob/master/bash-common-helpers.sh
#
function ask_to_continue() {
    local msg=${1}
    local waitingforanswer=true
    while ${waitingforanswer}; do
        read -p "${msg} (hit 'y/Y' to continue, 'n/N' to cancel) " -r -n 1 ynanswer
        case ${ynanswer} in
        [Yy])
            waitingforanswer=false
            break
            ;;
        [Nn])
            echo ""
            die 1 "Operation cancelled as requested!"
            ;;
        *)
            echo ""
            echo "Please answer either yes (y/Y) or no (n/N)."
            ;;
        esac
    done
    echo ""
}

function run_in_script_dir() {
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    cd "${script_dir}" || exit 1
}

function countdownWithNotice() {
    local seconds=${1}
    local message=${2}
    while [ "${seconds}" -gt 0 ]; do
        echo -ne "${message} in ${seconds} seconds\033[0K\r"
        sleep 1
        : $((seconds--))
    done
    echo -ne "\033[0K\r"
}
