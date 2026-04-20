# ─── History substring search (↑/↓) ──────────────────────────────────────────
# The brew package loads the widgets but does not bind keys. Bind both the raw
# escape sequences and the terminfo-resolved forms so it works under tmux and
# terminals with non-standard terminfo.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
[[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
[[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down

# ─── ESC-ESC: prepend sudo to current (or last) command ──────────────────────
# Ported from ohmyzsh/plugins/sudo. Toggles `sudo` / `sudo -e` based on $EDITOR.
__sudo-replace-buffer() {
  local old=$1 new=$2 space=${2:+ }
  if [[ $CURSOR -le ${#old} ]]; then
    BUFFER="${new}${space}${BUFFER#$old }"
    CURSOR=${#new}
  else
    LBUFFER="${new}${space}${LBUFFER#$old }"
  fi
}

sudo-command-line() {
  [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"

  local WHITESPACE=""
  if [[ ${LBUFFER:0:1} = " " ]]; then
    WHITESPACE=" "
    LBUFFER="${LBUFFER:1}"
  fi

  {
    local EDITOR=${SUDO_EDITOR:-${VISUAL:-$EDITOR}}

    if [[ -z "$EDITOR" ]]; then
      case "$BUFFER" in
        sudo\ -e\ *) __sudo-replace-buffer "sudo -e" "" ;;
        sudo\ *)     __sudo-replace-buffer "sudo" "" ;;
        *)           LBUFFER="sudo $LBUFFER" ;;
      esac
      return
    fi

    local cmd="${${(Az)BUFFER}[1]}"
    local realcmd="${${(Az)aliases[$cmd]}[1]:-$cmd}"
    local editorcmd="${${(Az)EDITOR}[1]}"

    if [[ "$realcmd" = (\$EDITOR|$editorcmd|${editorcmd:c}) \
      || "${realcmd:c}" = ($editorcmd|${editorcmd:c}) ]] \
      || builtin which -a "$realcmd" | command grep -Fx -q "$editorcmd"; then
      __sudo-replace-buffer "$cmd" "sudo -e"
      return
    fi

    case "$BUFFER" in
      $editorcmd\ *) __sudo-replace-buffer "$editorcmd" "sudo -e" ;;
      \$EDITOR\ *)   __sudo-replace-buffer '$EDITOR' "sudo -e" ;;
      sudo\ -e\ *)   __sudo-replace-buffer "sudo -e" "$EDITOR" ;;
      sudo\ *)       __sudo-replace-buffer "sudo" "" ;;
      *)             LBUFFER="sudo $LBUFFER" ;;
    esac
  } always {
    LBUFFER="${WHITESPACE}${LBUFFER}"
    zle && zle redisplay
  }
}

zle -N sudo-command-line
bindkey -M emacs '\e\e' sudo-command-line
bindkey -M vicmd '\e\e' sudo-command-line
bindkey -M viins '\e\e' sudo-command-line
