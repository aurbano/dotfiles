# ─── Single compinit with daily cache ────────────────────────────────────────
# One compinit call for the entire session. Uses -C (cached) if dump is <24h old.
autoload -Uz compinit
_comp_files=(${ZDOTDIR:-$HOME}/.zcompdump(Nm-24))
if (( ${#_comp_files} )); then
  compinit -C
else
  compinit
fi
unset _comp_files

if command -v terraform &>/dev/null; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi

zstyle ':completion:*' menu select

# Replay compdef calls that were buffered during OMZ plugin loading
for _def in "${_compdef_buffer[@]}"; do compdef $_def 2>/dev/null; done
unset _compdef_buffer _def
