# dotfiles

Personal macOS dotfiles. Managed with a single setup script.

## Install

```bash
git clone https://github.com/aurbano/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script is interactive — it checks what's missing and asks before making changes. Run with `--yes` to apply everything non-interactively, or `--module <name>` to run a single step.

## Update

```bash
./update.sh
```

Run periodically to refresh Homebrew packages, Neovim plugins (lazy.nvim + treesitter), Oh My Zsh plugins, TPM, and language toolchains (rustup, uv tools, pnpm globals, fnm LTS). Non-interactive by default; use `--dry-run` to preview or `--module <name>` for a single step.

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
| `tmux/tmux.conf` | Tmux config — Catppuccin theme, vim bindings, session restore |

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

## Tmux

Prefix is `Ctrl-a`.

After first install, open tmux and press `prefix + I` to install plugins (TPM).

### Sessions

| Command | Action |
|---------|--------|
| `t` | Create or attach session named `main` (fzf picker if inside tmux) |
| `t <name>` | Create or attach named session |
| `tl` | List sessions |
| `tk` | Kill current session |
| `prefix + $` | Rename current session |
| `prefix + s` | Session list / switcher |

### Windows (tabs)

| Key | Action |
|-----|--------|
| `prefix + c` | New window (opens in current dir) |
| `prefix + ,` | Rename window |
| `prefix + n` / `p` | Next / prev window |
| `prefix + <number>` | Jump to window by number |
| `prefix + &` | Kill window |

### Panes (splits)

| Key | Action |
|-----|--------|
| `prefix + \|` | Split vertically (side by side) |
| `prefix + -` | Split horizontally (top/bottom) |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + H/J/K/L` | Resize pane (repeatable) |
| `prefix + z` | Zoom pane (toggle fullscreen) |
| `prefix + x` | Kill pane |
| `prefix + {` / `}` | Swap pane left / right |

### Copy mode

| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `v` | Start selection (vi mode) |
| `y` | Copy selection to clipboard and exit |
| `q` | Quit copy mode |

### Sessions — save & restore (tmux-resurrect)

| Key | Action |
|-----|--------|
| `prefix + Ctrl-s` | Save session (panes, layout, cwd) |
| `prefix + Ctrl-r` | Restore saved session |

### Terminal integration

**iTerm2** — run `tit` to open tmux in control mode. iTerm2 maps tmux windows to native tabs and panes to native splits. Transparent once connected.

**Ghostty** — works out of the box. True color is enabled via `tmux-256color` in the config.

### Misc

| Key | Action |
|-----|--------|
| `prefix + r` | Reload tmux config |
| `prefix + d` | Detach from session |
| `prefix + ?` | Show all key bindings |

## Machine-local overrides

Put anything machine-specific in `~/.zshrc.local` — it's sourced last and not tracked.

Git credentials go in `~/.gitconfig.local`:

```ini
[user]
  name = Your Name
  email = you@example.com
```
