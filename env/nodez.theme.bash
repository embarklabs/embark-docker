# Author: Michael Bradley (https://github.com/michaelsbradleyjr/)
# Based on the zorg theme:
# https://github.com/Bash-it/bash-it/blob/master/themes/zork/zork.theme.bash

SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

SCM_THEME_PROMPT_DIRTY=" ${bold_red}✗${normal}"
SCM_THEME_PROMPT_CLEAN=" ${bold_green}✓${normal}"
SCM_GIT_CHAR="${bold_green}±${normal}"
SCM_SVN_CHAR="${bold_cyan}⑆${normal}"
SCM_HG_CHAR="${bold_red}☿${normal}"

__nodez_char_node="${bold_green}🄽 ${normal}"
__nodez_char_npm=📦

__nodez_ne() {
    local env=
    if [[ -v NVM_DIR ]]; then
        env="nvm"
    fi
    if [[ -v NODE_VIRTUAL_ENV ]]; then
        env="${NODE_VIRTUAL_ENV##*/}"
    fi
    if [[ "$env" != "" ]]; then
        env="[${bold_yellow}$env${normal}"
        if [[ ! -v NODE_VERSION ]]; then
            env+="]"
        fi
        echo "$env"
    fi
}

__nodez_nv() {
    if [[ -v NODE_VERSION ]]; then
        local nv="＝${__nodez_char_node}${NODE_VERSION}"
        nv+="${__nodez_char_npm}${NPM_VERSION}]"
        echo "$nv"
    fi
}

__nodez_scm_prompt() {
    [[ $(scm_char) != $SCM_NONE_CHAR ]] \
        && echo "[$(scm_char)][$(scm_prompt_info)]"
}

case $TERM in
    xterm*)
        __nodez_title="\[\033]0;\w\007\]" ;;
    *)
        __nodez_title="" ;;
esac

__nodez_ve(){
    [[ -n "$VIRTUAL_ENV" ]] \
        && echo "(${bold_purple}${VIRTUAL_ENV##*/}${normal})"
}

prompt() {
    local host="${green}\h${normal}";
    PS1="${__nodez_title}┌─"
    PS1+="$(__nodez_ve)"
    PS1+="[$host]"
    PS1+="$(__nodez_ne)$(__nodez_nv)"
    PS1+="$(__nodez_scm_prompt)"
    PS1+="[${cyan}\\w${normal}]"
    PS1+="
└─▪ "
}

PS2="└─▪ "
PS3=">> "

safe_append_prompt_command prompt
