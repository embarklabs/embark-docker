#requires -version 3.0

function Start-Embark {

    function Set-Value( [parameter( Mandatory = $false )] [string] $Var, $Default) {
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

    $EMBARK_DOCKER_MOUNT_SOURCE = Set-Value $Env:EMBARK_DOCKER_MOUNT_SOURCE $pwd
    $EMBARK_DOCKER_MOUNT_TARGET = Set-Value $Env:EMBARK_DOCKER_MOUNT_TARGET "/dapp"
    $EMBARK_DOCKER_RUN = $Env:EMBARK_DOCKER_RUN
    $EMBARK_DOCKER_IMAGE = Set-Value $Env:EMBARK_DOCKER_IMAGE "statusim/embark"
    $EMBARK_DOCKER_RUN_INTERACTIVE = Set-Value $Env:EMBARK_DOCKER_RUN_INTERACTIVE $false
    $EMBARK_DOCKER_RUN_OPTS_REPLACE = Set-Value $Env:EMBARK_DOCKER_RUN_OPTS_REPLACE $false
    $EMBARK_DOCKER_RUN_RM = Set-Value $Env:EMBARK_DOCKER_RUN_RM $true
    $EMBARK_DOCKER_TAG = Set-Value $Env:EMBARK_DOCKER_TAG "latest"

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
            $run_opts = $run_opts + @("-e", "$env_var")
        }
    }

    if ($EMBARK_DOCKER_RUN_RM -eq $true) {
        $run_opts = $run_opts + @("--rm")
    }

    $OldErrorActionPreference = $ErrorActionPreference

    # 'Continue' - Preference for printing errors and continuing the execution in case of non-terminating errors.
    $ErrorActionPreference = 'Continue'

    function Cleanup ( [parameter( Mandatory = $false )] [int] $RetVal) {
        Remove-Item -Path Function:\Set-Value
        Remove-Item -Path Function:\Confirm-Docker
        Remove-Item -Path Function:\Cleanup
        $ErrorActionPreference = $OldErrorActionPreference
        $Global:LASTEXITCODE = $RetVal
        return
    }

    function Confirm-Docker () {
        if (-not (Get-Command docker -errorAction SilentlyContinue)) {
            Write-Host "Error: " -ForegroundColor Red -NoNewline
            Write-Host "the command ``docker`` must be in a path on `$PATH or aliased"
            return 127
        }
        return 0
    }

    $docker_return_code = Confirm-Docker

    if ($docker_return_code) {
        return Cleanup -RetVal $docker_return_code
    }

    $had_run_opts = $false
    $_run_opts = @()
    $_cmd = @()
    $cmd = @()

    $i = 0
    while ($args[$i]) {
        if ($args[$i] -eq "---") {
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
        if ($cmd[0] -cin @("-V", "--version", "-h", "--help", "new", "demo", "build", "run", "blockchain", 
            "simulator", "test", "reset", "graph", "upload", "version")) {
            $cmd = @("embark") + $cmd
        }
    }
    else {
        $i_flag = ""
        if ($EMBARK_DOCKER_RUN_INTERACTIVE -eq $true) {
            $i_flag = "i"
        }

        $run_script = Get-Content $EMBARK_DOCKER_RUN

        # " doesn't get passed to the container so has to be replaced by \"
        $run_script = $run_script -join "`n" -replace '"', '\"'

        # do not alter indentation, tabs in lines below
        $run_script = "exec bash -${i_flag}s `$(tty) ${cmd} << 'RUN'
__tty=`$1
shift
script=/tmp/run_embark_script
cat << 'SCRIPT' > `$script
$run_script
SCRIPT
chmod +x `$script
exec `$script `$@ < `$__tty
RUN"
        # do not alter indentation, tabs in lines above

        $cmd = ("bash", "-${i_flag}c", "$run_script")
    }

    $opts = $run_opts + "${EMBARK_DOCKER_IMAGE}:${EMBARK_DOCKER_TAG}" + $cmd

    docker run $opts

    if (-not $?) {
        return Cleanup -RetVal 1
    }

    return Cleanup
}


# Invokes Start-Embark only if the source is this script.
if ($MyInvocation.InvocationName.EndsWith($MyInvocation.MyCommand.Name)) {
    Start-Embark @args
}
