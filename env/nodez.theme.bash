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
    if [[ -v NODE_VERSION ]]; then
        [ "$env" != "" ] && echo "[${bold_yellow}$env${normal}"
    else
        [ "$env" != "" ] && echo "[${bold_yellow}$env${normal}]"
    fi
}

__nodez_nv() {
    [[ -v NODE_VERSION ]] \
        && echo "→${__nodez_char_node}${NODE_VERSION}${__nodez_char_npm}${NPM_VERSION}]"
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