#!/usr/bin/env /bin/bash

## BASIC CONFIGURATIONS
COUNTRY=sg
SERVICE=openpyn.service
SLEEP_AFTER_RECONNECTING=5s
SLEEP_RETRY=5

## FORMATTING
S_BLACK=$(tput setaf 0)
S_RED=$(tput setaf 1)
S_GREEN=$(tput setaf 2)
S_YELLOW=$(tput setaf 3)
S_BLUE=$(tput setaf 4)
S_MAGENTA=$(tput setaf 5)
S_CYAN=$(tput setaf 6)
S_WHITE=$(tput setaf 7)
S_BOLD=$(tput bold)
S_DIM=$(tput dim)
S_RESET=$(tput sgr0)

## FUNCTIONS
function info {
    echo "${S_BOLD}${S_WHITE}${S_DIM}[INFO]${S_RESET} $1"
}

function warn {
    echo "${S_BOLD}${S_WHITE}${S_DIM}[WARNING]${S_RESET} ${S_YELLOW}$1${S_RESET}"
}

function err {
    echo "${S_BOLD}${S_WHITE}${S_DIM}[ERROR]${S_RESET} ${S_BOLD}${S_RED}$1${S_RESET}"
}

function pass_service_status_to_var {
    eval "${1}=\"$(systemctl show ${SERVICE} --no-page)\""
}

function parse_is_service_active {
    SERVICE_ACTIVE_STATE=$(printf '%s' "${SERVICE_STATUS}" | sed -E -n "s/^ActiveState=(.+)$/\1/p")
    [[ "$SERVICE_ACTIVE_STATE" == "active" ]] && return
    false
}

function echo_and_sleep {
    info "Sleeping for ${S_RED}${S_BOLD}${1}${S_RESET}..."
    sleep ${1}
}

## MAIN SCRIPT
if [ "$EUID" -ne 0 ]; then
    err "Please run this script as root (or add this script to sudoers file)"
    exit 1
fi

if [[ -z "$COUNTRY" ]]; then
    err "Country must be set, exiting..."
    exit 1
else
    info "Country set to ${S_RED}${S_BOLD}${COUNTRY^^}${S_RESET}, fetching servers list..."
    SAVEIFS=$IFS
    IFS=$'\n'
    SERVERS=($(openpyn -l ${COUNTRY} | sed -E -n "s/^server = ([a-zA-Z0-9]+).*/\1/ip"))
    IFS=$SAVEIFS

    SERVERS_STRING=$(printf ", %s" "${SERVERS[@]}")
    SERVERS_STRING=${SERVERS_STRING:1}
    SERVERS_COUNT=${#SERVERS[@]}
fi

info "${S_RED}${S_BOLD}${COUNTRY^^}${S_RESET} servers (${SERVERS_COUNT}):${S_BOLD}${S_GREEN}${SERVERS_STRING}${S_RESET}"
if [[ $SERVERS_COUNT -lt 2 ]]; then
    err "There are less than 2 servers in ${COUNTRY}, please consider using another country..."
    exit 1
fi

pass_service_status_to_var SERVICE_STATUS
NEXT_SERVER_INDEX=0

if parse_is_service_active "${SERVICE_STATUS}"; then
    # echo "ERROR: openpyn service is active, please stop and disable the service."
    info "openpyn service is already running..."

    LAST_SERVER=$(printf '%s' "${SERVICE_STATUS}" | sed -E -n "s/^ExecStart=.*--server ([a-zA-Z0-9]+).*$/\1/p")
    if [[ -n "$LAST_SERVER" ]]; then
        info "Currently connected to ${S_BOLD}${S_GREEN}${LAST_SERVER}${S_RESET}"
        LAST_SERVER_INDEX=
        for i in "${!SERVERS[@]}"; do
            if [[ "${SERVERS[$i]}" = "${LAST_SERVER}" ]]; then
                LAST_SERVER_INDEX=${i}
            fi
        done

        if [[ -n "$LAST_SERVER_INDEX" ]]; then
            info "Server ${S_BOLD}${S_GREEN}${LAST_SERVER}${S_RESET} is at index #${LAST_SERVER_INDEX} in ${S_RED}${S_BOLD}${COUNTRY^^}${S_RESET} servers array"
            NEXT_SERVER_INDEX=$(( LAST_SERVER_INDEX + 1 ))
            if [[ -n "${SERVERS[$NEXT_SERVER_INDEX]}" ]]; then
                info "Next server will be index #${NEXT_SERVER_INDEX} ${S_BOLD}${S_GREEN}${SERVERS[$NEXT_SERVER_INDEX]}${S_RESET}..."
            else
                NEXT_SERVER_INDEX=0
                info "It is the last server in the array, looping back to index #0 ${S_BOLD}${S_GREEN}${SERVERS[0]}${S_RESET}..."
            fi
        else
            warn "${LAST_SERVER} is not found in servers array, continuing with index #0 ${S_BOLD}${S_GREEN}${SERVERS[0]}${S_RESET}..."
        fi
    else
        warn "Currently connected server was not explicitly configured, continuing with index #0 ${S_BOLD}${S_GREEN}${SERVERS[0]}${S_RESET}..."
    fi
else
    warn "openpyn service is not running, continuing with index #0 ${S_BOLD}${S_GREEN}${SERVERS[0]}${S_RESET}..."
fi

openpyn --daemon --server ${SERVERS[$NEXT_SERVER_INDEX]} 2>&1

SUCCESS=$?
if [[ ${SUCCESS} -eq 0 ]]; then
    echo_and_sleep ${SLEEP_AFTER_RECONNECTING}

    N=0
    while [ "$N" -lt ${SLEEP_RETRY} ]; do
        N=$(( N + 1 ))
        pass_service_status_to_var SERVICE_STATUS

        if parse_is_service_active "${SERVICE_STATUS}"; then
            info "Service successfully restarted, exiting..."
            exit 0
        else
            echo_and_sleep ${SLEEP_AFTER_RECONNECTING}
        fi
    done
else
    err "Failed to rotate server, exiting..."
    exit 1
fi
