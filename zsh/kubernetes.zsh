# ─── Kubernetes (kubie) ─────────────────────────────────────────────────
# Kubie gives per-shell context/namespace isolation — switching in one
# terminal never affects another.

command -v kubie &>/dev/null || return

# ─── Aliases ───────────────────────────────────────────────────────────
alias k='kubectl'
alias kx='kubie ctx'
alias kn='kubie ns'

# ─── Completions (cached) ─────────────────────────────────────────────
_cached_source kubie kubie generate-completion

# ─── RPS1: show context/namespace on right side of prompt ─────────────
# Only displays inside a kubie shell (kubie sets KUBIE_ACTIVE and points
# KUBECONFIG at a per-shell temp file). `kubie ctx`/`kubie ns` rewrite that
# file, so the label is recomputed only when its mtime changes instead of
# forking kubie twice on every prompt.
zmodload -F zsh/stat b:zstat
typeset -g _kubie_prompt= _kubie_prompt_mtime=

_kubie_prompt_update() {
  if [[ -z $KUBIE_ACTIVE || ! -f $KUBECONFIG ]]; then
    _kubie_prompt= _kubie_prompt_mtime=
    return
  fi
  local mtime
  mtime=$(zstat +mtime -- $KUBECONFIG) || return
  [[ $mtime == $_kubie_prompt_mtime ]] && return
  _kubie_prompt_mtime=$mtime

  local ctx ns
  ctx=$(kubie info ctx 2>/dev/null)
  ns=$(kubie info ns 2>/dev/null)
  _kubie_prompt=${ctx:+"%F{242}⎈ ${ctx}/${ns:--}%f"}
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _kubie_prompt_update

# Prepend to RPS1 so it coexists with anything else on the right
RPS1='${_kubie_prompt}'" ${RPS1:-}"
