#!/usr/bin/env bash

run_embark () {
    local oldopts=""
    case $- in
        *e*) oldopts="set -e";;
        *) oldopts="set +e";;
    esac
    if [[ $(shopt -po history) = "set -o history" ]]; then
        oldopts="$oldopts; set -o history"
    fi
    set +e
    set +o history

    local txtbld=$(tput bold)
    local txtrst=$(tput sgr0)

    local bldcyn=${txtbld}$(tput setaf 6)
    local bldred=${txtbld}$(tput setaf 1)
    local bldylw=${txtbld}$(tput setaf 3)

    local ERROR=${bldred}ERROR${txtrst}
    local INFO=${bldcyn}INFO${txtrst}
    local WARNING=${bldylw}WARNING${txtrst}

    check_bash_version () {
        if [[ $BASH_VERSINFO -lt 4 ]]; then
            echo "$ERROR: this script requires Bash version >= 4.0"
            return 1
        fi
    }

    check_bash_version

    if [[ $? = 1 ]]; then
        unset check_bash_version
        eval "$oldopts"
        if [[ "$0" != "$BASH_SOURCE" ]]; then
            return 1
        else
            exit 1
        fi
    fi

    check_docker () {
        if ! type docker &> /dev/null; then
            echo "$ERROR: the command \`docker\` must be in a path on \$PATH or aliased"
            return 127
        fi
    }

    check_docker

    if [[ $? = 127 ]]; then
        unset check_bash_version
        unset check_docker
        eval "$oldopts"
        if [[ "$0" != "$BASH_SOURCE" ]]; then
            return 127
        else
            exit 127
        fi
    fi

    local dummy="-e __embark_docker_runsh"
    local EMBARK_DOCKER_EXTRA_RUN_OPTS=${EMBARK_DOCKER_EXTRA_RUN_OPTS:-$dummy}
    local EMBARK_DOCKER_MOUNT_SOURCE=${EMBARK_DOCKER_MOUNT_DIR:-$PWD}
    local EMBARK_DOCKER_MOUNT_TARGET=${EMBARK_DOCKER_MOUNT_DIR:-/dapp}
    local EMBARK_DOCKER_IMAGE=${EMBARK_DOCKER_IMAGE:-statusim/embark}
    local EMBARK_DOCKER_TAG=${EMBARK_DOCKER_TAG:-latest}

    local -a cmd=( "$@" )
    case $1 in
        -V|--version|-h|--help|new|demo|build|run|blockchain|simulator|test|\
            reset|graph|upload|version) cmd=( "embark" "$cmd" );;
    esac

    docker run \
           -it \
           -p 5001:5001 \
           -p 8000:8000 \
           -p 8080:8080 \
           -p 8500:8500 \
           -p 8545:8545 \
           -p 8546:8546 \
           -p 8555:8555 \
           -p 8556:8556 \
           -p 30301:30301/udp \
           -p 30303:30303 \
           -v ${EMBARK_DOCKER_MOUNT_SOURCE}:${EMBARK_DOCKER_MOUNT_TARGET} \
           -e TERM \
           "${EMBARK_DOCKER_EXTRA_RUN_OPTS}" \
           ${EMBARK_DOCKER_IMAGE}:${EMBARK_DOCKER_TAG} \
           "${cmd[@]}"

    local docker_exit_status=$?

    unset check_bash_version
    unset check_docker
    eval "$oldopts"

    if [[ $docker_exit_status != 0 ]]; then
        if [[ "$0" != "$BASH_SOURCE" ]]; then
            return $docker_exit_status
        else
            exit $docker_exit_status
        fi
    fi
}

if [[ "$0" = "$BASH_SOURCE" ]]; then
    run_embark "$@"
fi
