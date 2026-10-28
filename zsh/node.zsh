# ─── fnm (fast node manager) ────────────────────────────────────────────────
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Global npm installs (including CLIs that self-update with `npm i -g`)
# go to one prefix shared by every Node version, so switching or upgrading
# Node through fnm doesn't make them disappear.
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
path=($NPM_CONFIG_PREFIX/bin $path)

# yarn comes from corepack (per-project version via packageManager). Skip its
# interactive download prompt, which would hang non-interactive shells.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
