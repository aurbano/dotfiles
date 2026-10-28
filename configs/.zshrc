# Deduplicate PATH and fpath entries
typeset -U path fpath

# ─── Cached init scripts ────────────────────────────────────────────────────
# Generated init/completion scripts are cached and regenerated whenever the
# tool's binary is newer than the cache (i.e. after an upgrade) or the cache
# is empty, so shell start doesn't fork every tool every time.
# Usage: _cached_source <name> <command> [args...]
ZSH_CACHE_DIR=$HOME/.cache/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

_cached_source() {
  local cache=$ZSH_CACHE_DIR/$1.zsh bin=${commands[$2]:-$2}
  shift
  [[ -x $bin ]] || return 0
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    "$@" >| $cache 2>/dev/null || { rm -f $cache; return 0; }
  fi
  source $cache
}

# ─── Homebrew ───────────────────────────────────────────────────────────────
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x $_brew ]] && { _cached_source brew-shellenv $_brew shellenv zsh; break; }
done
unset _brew
BREW_PREFIX=${HOMEBREW_PREFIX:-/opt/homebrew}

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

# ─── Machine-specific config ────────────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ─── Syntax highlighting + history substring search (last) ──────────────────
# zsh-syntax-highlighting must come after every widget is defined, and
# history-substring-search after it (per both READMEs). Both come from brew.
if [[ -f $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if [[ -f $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  # Bind both the raw escape sequences and the terminfo forms so ↑/↓ work under
  # tmux and terminals with non-standard terminfo.
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  [[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
  [[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
fi
