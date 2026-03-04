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

# ─── Oh My Zsh ──────────────────────────────────────────────────────────────
export ZSH=~/dotfiles/.oh-my-zsh

# Pure prompt
fpath+=$BREW_PREFIX/share/zsh/site-functions
autoload -U promptinit; promptinit

# Completions fpath (before compinit)
fpath=(~/.zsh/completions $HOME/.docker/completions ~/.zfunc $fpath)

ZSH_THEME="" # Empty for pure prompt
COMPLETION_WAITING_DOTS="true"

# Source syntax-highlighting & substring-search from brew (faster than OMZ clones)
[[ -f $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
  source $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh

plugins=(
  autoupdate
  aws
  colored-man-pages
  colorize
  common-aliases
  dotenv
  git
  gitfast
  macos
  ssh-agent
  sudo
  yarn
)

# Defer compinit — OMZ calls it without -C (212ms). We stub it out here
# and call it once ourselves after all plugins/fpath are configured.
skip_global_compinit=1
ZSH_DISABLE_COMPFIX=true

# Stub compinit + compdef so OMZ's call is a no-op. Buffer compdef calls.
typeset -ga _compdef_buffer=()
compinit() { : }
compdef() { _compdef_buffer+=("${(j: :)@}") }
source $ZSH/oh-my-zsh.sh
unfunction compinit compdef 2>/dev/null

# ─── User config ────────────────────────────────────────────────────────────
source ~/dotfiles/configs/.functions
source ~/dotfiles/configs/.aliases

# ─── Zsh config modules ─────────────────────────────────────────────────────
for _zsh_conf in ~/dotfiles/zsh/*.zsh; do
  source "$_zsh_conf"
done
unset _zsh_conf

# ─── Prompt ──────────────────────────────────────────────────────────────────
prompt pure

# ─── Machine-specific config (last) ─────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
