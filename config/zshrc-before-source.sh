# commands to be ignore from timer plugin
TIMER_IGNORE_CMDS=(clear ls cd)

timer_ignore_preexec() {
  local cmd=${1%% *}

  for ignore in "${TIMER_IGNORE_CMDS[@]}"; do
    if [[ "$cmd" == "$ignore" ]]; then
      export TIMER_THRESHOLD=999999
      return
    fi
  done

  export TIMER_THRESHOLD=0
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec timer_ignore_preexec
