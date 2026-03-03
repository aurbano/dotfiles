# ─── Google Cloud SDK ────────────────────────────────────────────────────────
if [ -f "$BREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]; then
  . "$BREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$BREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]; then
  . "$BREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"
fi
