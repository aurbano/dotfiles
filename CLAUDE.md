# Dotfiles Repo — Claude Code Conventions

## Stack
- **Shell**: zsh
- **Package manager**: Homebrew — Brewfile at `tools/Brewfile`
- **Node**: fnm
- **Python**: uv
- **JS packages**: pnpm
- **Symlinks**: managed by `setup.sh`

## Structure
- `zsh/*.zsh` — modular shell config (history, completions, etc.)
- `configs/.aliases` — shell aliases
- `configs/.functions` — shell functions
- `configs/.gitconfig` — git config
- `tools/Brewfile` — Homebrew packages
- `claude/` — Claude Code config (CLAUDE.md, settings, hooks, agents)

## Notes
- Run `brew bundle --file=tools/Brewfile` after editing the Brewfile
- Run `./setup.sh` after adding new dotfiles to symlink them
