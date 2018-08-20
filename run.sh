#!/usr/bin/env bash

run_embark () {
    local EMBARK_DOCKER_MOUNT_SOURCE="${EMBARK_DOCKER_MOUNT_SOURCE:-$PWD}"
    local EMBARK_DOCKER_MOUNT_TARGET="${EMBARK_DOCKER_MOUNT_TARGET:-/dapp}"
    local EMBARK_DOCKER_IMAGE="${EMBARK_DOCKER_IMAGE:-statusim/embark}"
    local EMBARK_DOCKER_RUN="${EMBARK_DOCKER_RUN}"
    local EMBARK_DOCKER_RUN_INTERACTIVE=${EMBARK_DOCKER_RUN_INTERACTIVE:-false}
    local EMBARK_DOCKER_RUN_OPTS_REPLACE=${EMBARK_DOCKER_RUN_OPTS_REPLACE:-false}
    local EMBARK_DOCKER_RUN_RM=${EMBARK_DOCKER_RUN_RM:-true}
    local EMBARK_DOCKER_TAG="${EMBARK_DOCKER_TAG:-latest}"

    local -a run_opts=(
        "-i"
        "-t"
        "-p"
        "5001:5001"
        "-p"
        "8000:8000"
        "-p"
        "8080:8080"
        "-p"
        "8500:8500"
        "-p"
        "8545:8545"
        "-p"
        "8546:8546"
        "-p"
        "8555:8555"
        "-p"
        "8556:8556"
        "-p"
        "30301:30301/udp"
        "-p"
        "30303:30303"
        "-v"
        "${EMBARK_DOCKER_MOUNT_SOURCE}:${EMBARK_DOCKER_MOUNT_TARGET}"
    )

    if [[ -v LANG ]]; then
        run_opts=( "${run_opts[@]}" "-e" "LANG" )
    fi

    if [[ -v LANGUAGE ]]; then
        run_opts=( "${run_opts[@]}" "-e" "LANGUAGE" )
    fi

    if [[ -v LC_ALL ]]; then
        run_opts=( "${run_opts[@]}" "-e" "LC_ALL" )
    fi

    if [[ -v TERM ]]; then
        run_opts=( "${run_opts[@]}" "-e" "TERM" )
    fi

    if [[ $EMBARK_DOCKER_RUN_RM = true ]]; then
        run_opts=( "${run_opts[@]}" "--rm" )
    fi

    local txtbld=$(tput bold)
    local txtrst=$(tput sgr0)

    local bldcyn=${txtbld}$(tput setaf 6)
    local bldred=${txtbld}$(tput setaf 1)
    local bldylw=${txtbld}$(tput setaf 3)

    local ERROR=${bldred}ERROR${txtrst}
    local INFO=${bldcyn}INFO${txtrst}
    local WARNING=${bldylw}WARNING${txtrst}

    local oldopts
    case $- in
        *e*) oldopts="set -e" ;;
        *) oldopts="set +e" ;;
    esac
    set +e

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

    local had_run_opts=false
    local -a _run_opts=()
    local -a _cmd=()
    local -a cmd

    while [[ ! -z "$1" ]]; do
        if [[ "$1" = "--" ]]; then
            had_run_opts=true
        else
            if [[ $had_run_opts = true ]]; then
                _cmd=( "${_cmd[@]}" "$1" )
            else
                _run_opts=( "${_run_opts[@]}" "$1" )
            fi
        fi
        shift
    done

    if [[ $had_run_opts = true ]]; then
        cmd=( "${_cmd[@]}" )
        if [[ $EMBARK_DOCKER_RUN_OPTS_REPLACE = true ]]; then
            run_opts=( "${_run_opts[@]}" )
        else
            run_opts=( "${run_opts[@]}" "${_run_opts[@]}" )
        fi
    else
        cmd=( "${_run_opts[@]}" )
    fi

    if [[ -z "$EMBARK_DOCKER_RUN" ]]; then
        case "${cmd[0]}" in
            -V|--version|-h|--help|new|demo|build|run|blockchain|simulator|test|\
                reset|graph|upload|version) cmd=( "embark" "${cmd[@]}" ) ;;
        esac
    else
        local i_flag
        if [[ $EMBARK_DOCKER_RUN_INTERACTIVE = true ]]; then
            i_flag='i'
        else
            i_flag=''
        fi

        local run_script=$(< "$EMBARK_DOCKER_RUN")
        # do not alter indentation, tabs in lines below
        run_script=$(cat <<- RUN_SCRIPT
	exec bash -${i_flag}s \$(tty) ${cmd[@]} << 'RUN'
	__tty=\$1
	shift
	script=/tmp/run_embark_script
	cat << 'SCRIPT' > \$script
	$run_script
	SCRIPT
	chmod +x \$script
	exec \$script \$@ < \$__tty
	RUN
	RUN_SCRIPT
        )
        # do not alter indentation, tabs in lines above
        cmd=( "bash" "-${i_flag}c" "$run_script" )
    fi

    docker run \
           "${run_opts[@]}" \
           "${EMBARK_DOCKER_IMAGE}:${EMBARK_DOCKER_TAG}" \
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
export -f run_embark

if [[ "$0" = "$BASH_SOURCE" ]]; then
    run_embark "$@"
fi
