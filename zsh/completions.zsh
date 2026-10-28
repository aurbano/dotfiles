# ─── Single compinit with daily security check ──────────────────────────────
# One compinit call for the session. The full check (which also rewrites the
# dump and picks up new completions) runs when the dump is missing or older
# than 24 hours; otherwise -C trusts the cached dump.
autoload -Uz compinit
_zcompdump=$ZSH_CACHE_DIR/zcompdump
_stale_dump=($_zcompdump(N.mh+24))
if [[ ! -s $_zcompdump ]] || (( ${#_stale_dump} )); then
  compinit -d $_zcompdump
else
  compinit -C -d $_zcompdump
fi
unset _zcompdump _stale_dump

zstyle ':completion:*' menu select
