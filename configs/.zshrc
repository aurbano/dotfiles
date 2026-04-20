# Deduplicate PATH entries
typeset -U PATH

# ─── Cached brew prefix ─────────────────────────────────────────────────────
# Avoids a subprocess call on every shell start (~40ms saved)
# Regenerate: rm ~/.cache/zsh/brew_prefix
_brew_prefix_cache="$HOME/.cache/zsh/brew_prefix"
if [[ -f "$_brew_prefix_cache" ]]; then
  BREW_PREFIX="$(<$_brew_prefix_cache)"
else
  BREW_PREFIX="$(brew --prefix)"
  mkdir -p "${_brew_prefix_cache:h}"
  echo "$BREW_PREFIX" > "$_brew_prefix_cache"
fi
export PATH=$BREW_PREFIX/bin:$PATH

# ─── fpath (before compinit) ────────────────────────────────────────────────
# Pure prompt + brew-shipped completions (zsh-completions adds ~200 tools).
fpath=(
  ~/.zsh/completions
  $HOME/.docker/completions
  ~/.zfunc
  $BREW_PREFIX/share/zsh-completions
  $BREW_PREFIX/share/zsh/site-functions
  $fpath
)

# ─── Prompt ──────────────────────────────────────────────────────────────────
autoload -U promptinit; promptinit

# ─── Syntax highlighting + history substring search ─────────────────────────
# Order matters: syntax-highlighting first, then history-substring-search
# (per h-s-s README). Both come from brew, not a framework.
[[ -f $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
  source $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# ─── User config ────────────────────────────────────────────────────────────
source ~/dotfiles/configs/.functions
source ~/dotfiles/configs/.aliases

# ─── Zsh config modules ─────────────────────────────────────────────────────
for _zsh_conf in ~/dotfiles/zsh/*.zsh; do
  source "$_zsh_conf"
done
unset _zsh_conf

# ─── Activate prompt ────────────────────────────────────────────────────────
prompt pure

# ─── Machine-specific config (last) ─────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
