# ─── PATH additions ─────────────────────────────────────────────────────────
export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"
path=($HOME/.local/bin $PNPM_HOME $BUN_INSTALL/bin $path)

[[ -s $BUN_INSTALL/_bun ]] && source $BUN_INSTALL/_bun

# ─── fzf, atuin, zoxide, uv (cached init) ───────────────────────────────────
_cached_source fzf fzf --zsh
# atuin after fzf so it takes over Ctrl-R; ↑/↓ stay with history-substring-search
export ATUIN_CONFIG_DIR="$HOME/dotfiles/atuin"
_cached_source atuin atuin init zsh --disable-up-arrow
_cached_source zoxide zoxide init zsh
_cached_source uv uv generate-shell-completion zsh
_cached_source uvx uvx --generate-shell-completion zsh
