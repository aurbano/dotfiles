# ─── Kubernetes (kubie) ─────────────────────────────────────────────────
# Kubie gives per-shell context/namespace isolation — switching in one
# terminal never affects another.

command -v kubie &>/dev/null || return

# ─── Aliases ───────────────────────────────────────────────────────────
alias k='kubectl'
alias kx='kubie ctx'
alias kn='kubie ns'

# ─── Completions (cached) ─────────────────────────────────────────────
_zsh_cache="$HOME/.cache/zsh"
if [[ ! -f "$_zsh_cache/kubie.zsh" ]]; then
  mkdir -p "$_zsh_cache"
  kubie generate-completion 2>/dev/null > "$_zsh_cache/kubie.zsh"
fi
[[ -f "$_zsh_cache/kubie.zsh" ]] && source "$_zsh_cache/kubie.zsh"
unset _zsh_cache

# ─── RPS1: show context/namespace on right side of prompt ─────────────
# Only displays when inside a kubie shell (KUBIE_ACTIVE is set by kubie).
# Uses muted gray so it doesn't compete with Pure's left prompt.
_kubie_rprompt() {
  if [[ -n "$KUBIE_ACTIVE" ]]; then
    local ctx ns
    ctx="$(kubie info ctx 2>/dev/null)"
    ns="$(kubie info ns 2>/dev/null)"
    if [[ -n "$ctx" ]]; then
      echo "%F{242}⎈ ${ctx}/${ns:--}%f"
    fi
  fi
}

# Prepend to RPS1 so it coexists with anything else on the right
RPS1='$(_kubie_rprompt)'" ${RPS1:-}"
