function Run-Embark {

    function Assign-Value( [parameter( Mandatory = $false )] [string] $Var, $Default) {
        begin{
            if(-not ($Var)) {
                $Var = $Default
            }
        }
        process{
            return $Var
        }
        end{}
    }

    $EMBARK_DOCKER_MOUNT_SOURCE = Assign-Value $Env:EMBARK_DOCKER_MOUNT_SOURCE $pwd
    $EMBARK_DOCKER_MOUNT_TARGET = Assign-Value $Env:EMBARK_DOCKER_MOUNT_TARGET "/dapp"
    $EMBARK_DOCKER_RUN = $Env:EMBARK_DOCKER_RUN
    $EMBARK_DOCKER_IMAGE = Assign-Value $Env:EMBARK_DOCKER_IMAGE "statusim/embark"
    $EMBARK_DOCKER_RUN_INTERACTIVE = Assign-Value $Env:EMBARK_DOCKER_RUN_INTERACTIVE $false
    $EMBARK_DOCKER_RUN_OPTS_REPLACE = Assign-Value $Env:EMBARK_DOCKER_RUN_OPTS_REPLACE $false
    $EMBARK_DOCKER_RUN_RM = Assign-Value $Env:EMBARK_DOCKER_RUN_RM $true
    $EMBARK_DOCKER_TAG = Assign-Value $Env:EMBARK_DOCKER_TAG "latest"

    $run_opts = @(
        "-i",
        "-t",
        "-p",
        "5001:5001",
        "-p",
        "8000:8000",
        "-p",
        "8080:8080",
        "-p",
        "8500:8500",
        "-p",
        "8545:8545",
        "-p",
        "8546:8546",
        "-p",
        "8555:8555",
        "-p",
        "8556:8556",
        "-p",
        "30301:30301/udp",
        "-p",
        "30303:30303",
        "-v",
        "${EMBARK_DOCKER_MOUNT_SOURCE}:${EMBARK_DOCKER_MOUNT_TARGET}"
    )

    foreach ($env_var in "LANG", "LANGUAGE", "LC_ALL", "TERM") {
        if (Test-Path "Env:$env_var") {
            $run_opts = $run_opts + "-e" + "$env_var"
        }
    }

    if ($EMBARK_DOCKER_RUN_RM -eq $true) {
        $run_opts = $run_opts + "--rm"
    }

    function Cleanup {
        $retval = $lastexitcode
        Remove-Item -Path Function:\Check-Docker
        Remove-Item -Path Function:\Cleanup
        return $retval
    }

    function Check-Docker () {
        if (-not (Get-Command docker -errorAction SilentlyContinue)) {
            "Error: the command \`docker\` must be in a path on \$PATH or aliased"
            return 127
        }
    }

    Check-Docker

    $had_run_opts = $false
    $_run_opts = @()
    $_cmd = @()
    $cmd = @()

    $i = 1
    while ($args[$i]) {
        if ($args[$i] -eq "--") {
            $had_run_opts = $true
        }
        else {
            if ($had_run_opts -eq $true) {
                $_cmd = $_cmd + $args[$i]
            }
            else {
                $_run_opts = $_run_opts + $args[$i]
            }
        }
        $i++
    }

    if ($had_run_opts -eq $true) {
        $cmd = $_cmd
        if ($EMBARK_DOCKER_RUN_OPTS_REPLACE -eq $true) {
            $run_opts = $_run_opts
        }
        else {
            $run_opts = $run_opts + $_run_opts
        }
    }
    else {
        $cmd = $_run_opts
    }

    if (-not ($EMBARK_DOCKER_RUN)) {
        switch ($cmd[0]) {
            "-V" {}
            "--version" {}
            "-h" {}
            "--help" {}
            "new" {}
            "demo" {}
            "build" {}
            "run" {}
            "blockchain" {}
            "simulator" {}
            "test" {}
            "reset" {}
            "graph" {}
            "upload" {}
            "version" {
                $cmd = "embark" + $cmd
                break
            }
        }
    }
    else {
        $i_flag = ""
        if ($EMBARK_DOCKER_RUN_INTERACTIVE = $true) {
            $i_flag = "i"
        }

        $run_script = Get-Content $EMBARK_DOCKER_RUN
        "${cmd}"
        $run_script = "
    exec bash -${i_flag}s `$(tty) ${cmd} << 'RUN'
	__tty=`$1
	shift
	script=/tmp/run_embark_script
	cat << 'SCRIPT' > `$script
	$run_script
	SCRIPT
	chmod +x `$script
	exec `$script `$@ < `$__tty
	RUN
        "
        $cmd = ("bash", "-${i_flag}c", "$run_script")
    }

    $opts = @()

    if ($cmd) {
        $opts = $run_opts + "${EMBARK_DOCKER_IMAGE}:${EMBARK_DOCKER_TAG}" + $cmd
    }
    else {
        $opts = $run_opts + "${EMBARK_DOCKER_IMAGE}:${EMBARK_DOCKER_TAG}"
    }

    docker run $opts

    Cleanup
}

Run-Embark
