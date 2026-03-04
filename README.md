# dotfiles

Personal macOS dotfiles. Managed with a single setup script.

## Install

```bash
git clone https://github.com/aurbano/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script is interactive — it checks what's missing and asks before making changes. Run with `--yes` to apply everything non-interactively, or `--module <name>` to run a single step.

## What's included

| File | Purpose |
|------|---------|
| `configs/.zshrc` | Shell config — Oh My Zsh, pure prompt, deferred compinit |
| `zsh/` | Modular shell config (history, node, python, tools, gcloud) |
| `configs/.aliases` | Aliases with modern tool replacements (bat, eza, fd, rg, delta) |
| `configs/.functions` | Shell functions (extract, port, serve, whois, …) |
| `configs/.gitconfig` | Git config — delta pager, histogram diffs, rebase defaults |
| `nvim/` | Neovim config — lazy.nvim, treesitter, telescope, catppuccin |
| `tools/Brewfile` | All Homebrew dependencies |
| `configs/.curlrc` | Sensible curl defaults |

## Neovim keymaps

Leader is `,`.

| Key | Action |
|-----|--------|
| `,e` | Toggle file tree |
| `,ff` | Fuzzy find files |
| `,fg` | Live grep |
| `,fb` | Switch buffer |
| `gb` / `gB` | Next / prev buffer |
| `,x` | Close buffer |

## Machine-local overrides

Put anything machine-specific in `~/.zshrc.local` — it's sourced last and not tracked.

Git credentials go in `~/.gitconfig.local`:

```ini
[user]
  name = Your Name
  email = you@example.com
```
