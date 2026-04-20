# Non-default zsh options that Oh My Zsh used to set silently.
# Grouped by theme; each is a deliberate choice, not a default.

setopt AUTO_CD              # `somedir` -> cd somedir
setopt AUTO_PUSHD           # cd pushes onto the dirstack
setopt PUSHD_IGNORE_DUPS    # no duplicates in dirstack
setopt PUSHD_SILENT         # don't print dirstack after pushd/popd
setopt EXTENDED_GLOB        # ^, ~, # in glob patterns
setopt INTERACTIVE_COMMENTS # allow `# comments` in interactive shell
setopt NO_BEEP              # silence the terminal bell
