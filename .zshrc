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
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Change z storage dir
export _Z_DATA="$HOME/.cache/zsh/.z"

# Source syntax-highlighting & substring-search from brew (faster than OMZ clones)
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh

plugins=(
  autoupdate
  aws
  colored-man-pages
  colorize
  common-aliases
  dotenv
  git
  git-escape-magic
  gitfast
  iterm2
  macos
  ssh-agent
  sudo
  yarn
  z
)

# Defer compinit — OMZ calls it without -C (212ms). We stub it out here
# and call it once ourselves after all plugins/fpath are configured.
skip_global_compinit=1
DISABLE_COMPFIX=true

# Stub compinit + compdef so OMZ's call is a no-op. Buffer compdef calls.
typeset -ga _compdef_buffer=()
compinit() { : }
compdef() { _compdef_buffer+=("${(j: :)@}") }
source $ZSH/oh-my-zsh.sh
unfunction compinit compdef 2>/dev/null

# ─── User config ────────────────────────────────────────────────────────────
source ~/dotfiles/.functions
source ~/dotfiles/.aliases

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

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

zstyle ':completion:*' menu select

# Replay compdef calls that were buffered during OMZ plugin loading
# (git alias completions may warn about unknown services — harmless, silenced)
for _def in "${_compdef_buffer[@]}"; do compdef $_def 2>/dev/null; done
unset _compdef_buffer _def

# ─── NVM (lazy-loaded) ──────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
# Add default node to PATH eagerly so non-interactive shells (git hooks) find npm
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _nvm_default_path="$NVM_DIR/versions/node/$(ls "$NVM_DIR/versions/node" | sort -V | tail -1)/bin"
  [[ -d "$_nvm_default_path" ]] && export PATH="$_nvm_default_path:$PATH"
  unset _nvm_default_path
fi
__nvm_lazy_load() {
  unalias npm 2>/dev/null
  unset -f nvm node npm npx
  [ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && . "$BREW_PREFIX/opt/nvm/nvm.sh"
  [ -s "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
}
nvm() { __nvm_lazy_load; nvm "$@"; }
node() { __nvm_lazy_load; node "$@"; }
unalias npm 2>/dev/null
npm() { __nvm_lazy_load; npm "$@"; }
npx() { __nvm_lazy_load; npx "$@"; }

# ─── Pyenv (lazy-loaded) ────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
pyenv() {
  unset -f pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

# ─── PATH additions ─────────────────────────────────────────────────────────
export PATH=$HOME/.local/bin:$PATH

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export DEPOT_INSTALL_DIR="$HOME/.depot/bin"
export PATH="$DEPOT_INSTALL_DIR:$PATH"

# Python virtualenvs
export WORKON_HOME=~/.virtualenvs
[[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME

export GPG_TTY=$(tty)

# Google Cloud SDK
if [ -f "$BREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]; then . "$BREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$BREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]; then . "$BREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"; fi

# ─── Prompt ──────────────────────────────────────────────────────────────────
prompt pure

# ─── twig completion (cached) ────────────────────────────────────────────────
_zsh_cache="$HOME/.cache/zsh"
if [[ ! -f "$_zsh_cache/twig.zsh" ]] && command -v twig &>/dev/null; then
  twig --completion > "$_zsh_cache/twig.zsh" 2>/dev/null
fi
[[ -f "$_zsh_cache/twig.zsh" ]] && source "$_zsh_cache/twig.zsh"

# ─── fzf & zoxide (cached init) ─────────────────────────────────────────────
# Cache the output of `fzf --zsh` and `zoxide init zsh` to files.
# Regenerate: rm ~/.cache/zsh/{fzf,zoxide,twig}.zsh
if [[ ! -f "$_zsh_cache/fzf.zsh" ]] && command -v fzf &>/dev/null; then
  fzf --zsh > "$_zsh_cache/fzf.zsh" 2>/dev/null
fi
[[ -f "$_zsh_cache/fzf.zsh" ]] && source "$_zsh_cache/fzf.zsh"

if [[ ! -f "$_zsh_cache/zoxide.zsh" ]] && command -v zoxide &>/dev/null; then
  zoxide init zsh > "$_zsh_cache/zoxide.zsh" 2>/dev/null
fi
[[ -f "$_zsh_cache/zoxide.zsh" ]] && source "$_zsh_cache/zoxide.zsh"

unset _zsh_cache

# ─── Machine-specific config (last) ─────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
