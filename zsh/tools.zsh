# ─── PATH additions ─────────────────────────────────────────────────────────
export PATH=$HOME/.local/bin:$PATH

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export DEPOT_INSTALL_DIR="$HOME/.depot/bin"
export PATH="$DEPOT_INSTALL_DIR:$PATH"

export GPG_TTY=$(tty)

# ─── twig completion (cached) ────────────────────────────────────────────────
_zsh_cache="$HOME/.cache/zsh"
if [[ ! -f "$_zsh_cache/twig.zsh" ]] && command -v twig &>/dev/null; then
  twig --completion > "$_zsh_cache/twig.zsh" 2>/dev/null
fi
[[ -f "$_zsh_cache/twig.zsh" ]] && source "$_zsh_cache/twig.zsh"

# ─── fzf & zoxide (cached init) ─────────────────────────────────────────────
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
