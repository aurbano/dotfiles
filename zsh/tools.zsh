# ─── PATH additions ─────────────────────────────────────────────────────────
export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"
path=($HOME/.local/bin $PNPM_HOME $BUN_INSTALL/bin $path)

[[ -s $BUN_INSTALL/_bun ]] && source $BUN_INSTALL/_bun

# ─── fzf, zoxide, uv (cached init) ──────────────────────────────────────────
_cached_source fzf fzf --zsh
_cached_source zoxide zoxide init zsh
_cached_source uv uv generate-shell-completion zsh
_cached_source uvx uvx --generate-shell-completion zsh
