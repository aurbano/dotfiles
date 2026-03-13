#!/usr/bin/env bash
set -euo pipefail

# ─── Dotfiles setup ─────────────────────────────────────────────────────────
# Replaces: setup-a-new-machine.sh, setup-plugins.sh, custom_plugins.zsh,
#           symlink-setup.sh, brew.sh, update.sh
#
# Usage:
#   ./setup.sh                     # Full interactive run
#   ./setup.sh --yes               # Non-interactive, apply all
#   ./setup.sh --dry-run           # Show diff only, apply nothing
#   ./setup.sh --module symlinks   # Run a single module
#   ./setup.sh --reverse           # Detect system → dotfiles changes
#   ./setup.sh --status            # Quick overview

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Globals ─────────────────────────────────────────────────────────────────
AUTO_YES=false
DRY_RUN=false
SINGLE_MODULE=""
REVERSE_MODE=false
STATUS_MODE=false

# ─── Color / output helpers ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header()  { printf "\n${PURPLE}=== %s ===${NC}\n\n" "$1"; }
print_success() { printf "${GREEN}  [=] %s${NC}\n" "$1"; }
print_add()     { printf "${CYAN}  [+] %s${NC}\n" "$1"; }
print_warn()    { printf "${YELLOW}  [!] %s${NC}\n" "$1"; }
print_error()   { printf "${RED}  [✖] %s${NC}\n" "$1"; }
print_info()    { printf "${BLUE}  [i] %s${NC}\n" "$1"; }
print_skip()    { printf "  [-] %s\n" "$1"; }

answer_is_yes() { [[ "$REPLY" =~ ^[Yy]$ ]]; }

ask_for_confirmation() {
  if $AUTO_YES; then
    REPLY="y"
    return 0
  fi
  printf "${YELLOW}  [?] %s (y/n) ${NC}" "$1"
  read -r -n 1
  printf "\n"
}

ask_apply() {
  if $AUTO_YES; then return 0; fi
  if $DRY_RUN; then return 1; fi
  printf "${YELLOW}  [?] Apply? (y)es / (n)o: ${NC}"
  read -r -n 1
  printf "\n"
  answer_is_yes
}

# ─── Parse CLI args ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)      AUTO_YES=true; shift ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --module)   SINGLE_MODULE="$2"; shift 2 ;;
    --reverse)  REVERSE_MODE=true; shift ;;
    --status)   STATUS_MODE=true; shift ;;
    -h|--help)
      echo "Usage: ./setup.sh [--yes] [--dry-run] [--module NAME] [--reverse] [--status]"
      echo ""
      echo "Modules: xcode, homebrew, brewpkgs, symlinks, omz, shell-tools, nvim, toolchains, llm, tmux, claude, macos"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ─── Module: Xcode CLT ──────────────────────────────────────────────────────
mod_xcode() {
  print_header "Xcode Command Line Tools"

  if xcode-select -p &>/dev/null; then
    print_success "Xcode CLT installed ($(xcode-select -p))"
  else
    print_add "Xcode CLT not found (will install)"
    if ask_apply; then
      xcode-select --install
      echo "Waiting for Xcode CLT installation to complete..."
      while ! xcode-select -p &>/dev/null; do sleep 5; done
      print_success "Xcode CLT installed"
    fi
  fi
}

# ─── Module: Homebrew ────────────────────────────────────────────────────────
mod_homebrew() {
  print_header "Homebrew"

  if command -v brew &>/dev/null; then
    print_success "Homebrew installed ($(brew --prefix))"
  else
    print_add "Homebrew not found (will install)"
    if ask_apply; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      print_success "Homebrew installed"
    fi
  fi
}

# ─── Module: Brew packages ──────────────────────────────────────────────────
mod_brewpkgs() {
  print_header "Brew Packages"

  if ! command -v brew &>/dev/null; then
    print_error "Homebrew not installed — skipping"
    return
  fi

  local brewfile="$DOTFILES_DIR/tools/Brewfile"
  if [[ ! -f "$brewfile" ]]; then
    print_error "Brewfile not found at $brewfile"
    return
  fi

  # Snapshot installed packages (one brew call each, then fast lookups)
  local tmp_brews tmp_casks
  tmp_brews="$(mktemp)"
  tmp_casks="$(mktemp)"
  trap "rm -f '$tmp_brews' '$tmp_casks'" RETURN

  brew list --formula -1 2>/dev/null | sort > "$tmp_brews"
  brew list --cask -1 2>/dev/null | sort > "$tmp_casks"

  # Parse Brewfile and check against snapshots
  local -a missing_brews=()
  local -a missing_casks=()
  local -a wanted_brews=()
  local -a wanted_casks=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^brew\ \"([^\"]+)\" ]]; then
      local pkg="${BASH_REMATCH[1]}"
      wanted_brews+=("$pkg")
      if grep -qx "$pkg" "$tmp_brews"; then
        print_success "$pkg"
      else
        print_add "$pkg (missing)"
        missing_brews+=("$pkg")
      fi
    elif [[ "$line" =~ ^cask\ \"([^\"]+)\" ]]; then
      local pkg="${BASH_REMATCH[1]}"
      wanted_casks+=("$pkg")
      if grep -qx "$pkg" "$tmp_casks"; then
        print_success "$pkg (cask)"
      else
        print_add "$pkg (cask, missing)"
        missing_casks+=("$pkg")
      fi
    fi
  done < "$brewfile"

  if [[ ${#missing_brews[@]} -eq 0 && ${#missing_casks[@]} -eq 0 ]]; then
    print_info "All Brewfile packages are installed"
    return
  fi

  print_info "${#missing_brews[@]} brew(s) and ${#missing_casks[@]} cask(s) to install"

  if ask_apply; then
    brew bundle --file="$brewfile"
    print_success "brew bundle complete"
  fi
}

# ─── Module: Symlinks ────────────────────────────────────────────────────────

# Explicit symlink map
declare -a SYMLINK_FILES=(
  .aliases
  .curlrc
  .dircolors
  .functions
  .gitattributes
  .gitconfig
  .zshrc
)
declare -a SYMLINK_DIRS=(
  bin
  .gitignore
)

# Symlinks where the target is ~/.config/<name> instead of ~/<name>
declare -a CONFIG_SYMLINK_DIRS=(
  nvim
  ghostty
  tmux
)

_apply_symlink() {
  local source_path="$1"
  local target_path="$2"
  local label="$3"

  if [[ ! -e "$source_path" ]]; then
    print_warn "$label — source missing in dotfiles"
    return
  fi

  if [[ -L "$target_path" ]]; then
    local current_target
    current_target="$(readlink "$target_path")"
    if [[ "$current_target" == "$source_path" ]]; then
      print_success "$label -> $source_path"
    else
      print_warn "$label -> $current_target (expected $source_path)"
      if ask_apply; then
        rm -f "$target_path"
        ln -s "$source_path" "$target_path"
        print_success "$label -> $source_path (fixed)"
      fi
    fi
  elif [[ -e "$target_path" ]]; then
    print_warn "$label exists (regular file, not symlink)"
    ask_for_confirmation "Overwrite $label with symlink?"
    if answer_is_yes && ! $DRY_RUN; then
      rm -rf "$target_path"
      ln -s "$source_path" "$target_path"
      print_success "$label -> $source_path (replaced)"
    fi
  else
    print_add "$label (will create)"
    if ask_apply; then
      mkdir -p "$(dirname "$target_path")"
      ln -s "$source_path" "$target_path"
      print_success "$label -> $source_path (created)"
    fi
  fi
}

mod_symlinks() {
  print_header "Symlinks"

  # Ensure cache dir exists
  mkdir -p ~/.cache/zsh

  for item in "${SYMLINK_FILES[@]}"; do
    _apply_symlink "$DOTFILES_DIR/configs/$item" "$HOME/$item" "~/$item"
  done
  for item in "${SYMLINK_DIRS[@]}"; do
    _apply_symlink "$DOTFILES_DIR/$item" "$HOME/$item" "~/$item"
  done

  # ~/.config/<name> symlinks
  for item in "${CONFIG_SYMLINK_DIRS[@]}"; do
    _apply_symlink "$DOTFILES_DIR/$item" "$HOME/.config/$item" "~/.config/$item"
  done

  # Offer to create ~/.zshrc.local from example
  if [[ ! -f "$HOME/.zshrc.local" ]]; then
    print_add "~/.zshrc.local does not exist"
    ask_for_confirmation "Create from .zshrc.local.example?"
    if answer_is_yes && ! $DRY_RUN; then
      cp "$DOTFILES_DIR/configs/.zshrc.local.example" "$HOME/.zshrc.local"
      print_success "~/.zshrc.local created (edit to customize)"
    fi
  else
    print_success "~/.zshrc.local exists"
  fi
}

# ─── Module: Oh My Zsh + plugins ────────────────────────────────────────────

OMZ_PLUGIN_LIST=(
  "autoupdate|https://github.com/TamCore/autoupdate-oh-my-zsh-plugins"
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-completions|https://github.com/zsh-users/zsh-completions"
  "zsh-better-npm-completion|https://github.com/lukechilds/zsh-better-npm-completion"
)

mod_omz() {
  print_header "Oh My Zsh + Plugins"

  local omz_dir="$DOTFILES_DIR/.oh-my-zsh"
  if [[ -d "$omz_dir" ]]; then
    print_success "Oh My Zsh installed"
  else
    print_add "Oh My Zsh not found (will clone)"
    if ask_apply; then
      git clone https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
      print_success "Oh My Zsh cloned"
    fi
  fi

  local custom_dir="${ZSH_CUSTOM:-$omz_dir/custom}"
  local plugin_dir="$custom_dir/plugins"

  for entry in "${OMZ_PLUGIN_LIST[@]}"; do
    local plugin="${entry%%|*}"
    local url="${entry#*|}"
    local dest="$plugin_dir/$plugin"
    if [[ -d "$dest" ]]; then
      print_success "$plugin"
    else
      print_add "$plugin (will clone)"
      if ask_apply; then
        git clone "$url" "$dest"
        print_success "$plugin cloned"
      fi
    fi
  done

}

# ─── Module: Shell tools (pure, pygments, git-open) ─────────────────────────
mod_shell_tools() {
  print_header "Shell Tools"

  local brew_prefix="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || echo /opt/homebrew)}"

  # Pure prompt (installed via brew, check site-functions)
  if [[ -f "$brew_prefix/share/zsh/site-functions/prompt_pure_setup" ]]; then
    print_success "Pure prompt (via brew)"
  elif command -v prompt_pure_setup &>/dev/null; then
    print_success "Pure prompt (found in fpath)"
  else
    print_add "Pure prompt not found"
    if ask_apply; then
      brew install pure || print_error "Could not install pure prompt"
    fi
  fi

  # Pygments (for colorize plugin)
  if command -v pygmentize &>/dev/null; then
    print_success "Pygments"
  else
    print_add "Pygments not found (used by colorize plugin)"
    if ask_apply; then
      brew install pygments
      print_success "Pygments installed"
    fi
  fi

  # git-open
  if command -v git-open &>/dev/null; then
    print_success "git-open"
  else
    print_add "git-open not found"
    if ask_apply; then
      npm install --global git-open 2>/dev/null || print_warn "Could not install git-open (npm not available)"
    fi
  fi
}

# ─── Module: Neovim ──────────────────────────────────────────────────────────
mod_vim() {
  print_header "Neovim"

  if ! command -v nvim &>/dev/null; then
    print_add "neovim not found"
    if ask_apply; then
      brew install neovim
      print_success "neovim installed"
    fi
    return
  fi

  print_success "neovim ($(nvim --version | head -1))"

  local lazy_dir="$HOME/.local/share/nvim/lazy/lazy.nvim"
  if [[ -d "$lazy_dir" ]]; then
    print_success "lazy.nvim installed"
  else
    print_add "lazy.nvim not installed (will bootstrap on first nvim launch)"
    print_info "Run: nvim"
  fi

  # Nerd Font (required for lualine icons and nvim-web-devicons)
  if brew list --cask font-hack-nerd-font &>/dev/null; then
    print_success "Hack Nerd Font installed"
  else
    print_add "Hack Nerd Font not found (needed for nvim icons)"
    if ask_apply; then
      brew install --cask font-hack-nerd-font
      print_success "Hack Nerd Font installed"
      print_info "Set 'Hack Nerd Font Mono' in your terminal font settings"
    fi
  fi
}

# ─── Module: Toolchains ─────────────────────────────────────────────────────
mod_toolchains() {
  print_header "Toolchains"

  # fnm
  if command -v fnm &>/dev/null; then
    print_success "fnm ($(fnm --version 2>/dev/null))"
  else
    print_add "fnm not found"
    ask_for_confirmation "Install fnm?"
    if answer_is_yes && ! $DRY_RUN; then
      brew install fnm
      print_success "fnm installed"
    else
      print_skip "fnm skipped"
    fi
  fi

  # pyenv
  if command -v pyenv &>/dev/null; then
    print_success "pyenv ($(pyenv --version 2>&1 | awk '{print $2}'))"
  else
    print_add "pyenv not found"
    ask_for_confirmation "Install pyenv?"
    if answer_is_yes && ! $DRY_RUN; then
      brew install pyenv
      print_success "pyenv installed"
    else
      print_skip "pyenv skipped"
    fi
  fi

  # Cargo/Rust
  if [[ -f "$HOME/.cargo/env" ]] || command -v cargo &>/dev/null; then
    print_success "Cargo/Rust"
  else
    print_add "Cargo/Rust not found"
    ask_for_confirmation "Install Rust via rustup?"
    if answer_is_yes && ! $DRY_RUN; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      print_success "Rust installed"
    else
      print_skip "Rust skipped"
    fi
  fi

  # Google Cloud SDK
  local brew_prefix="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || echo /opt/homebrew)}"
  if [[ -f "$brew_prefix/share/google-cloud-sdk/path.zsh.inc" ]] || command -v gcloud &>/dev/null; then
    print_success "Google Cloud SDK"
  else
    print_add "gcloud not found"
    ask_for_confirmation "Install Google Cloud SDK?"
    if answer_is_yes && ! $DRY_RUN; then
      brew install --cask google-cloud-sdk
      print_success "gcloud installed"
    else
      print_skip "gcloud skipped"
    fi
  fi

  # pnpm
  if command -v pnpm &>/dev/null; then
    print_success "pnpm ($(pnpm --version 2>/dev/null))"
  else
    print_add "pnpm not found"
    ask_for_confirmation "Install pnpm?"
    if answer_is_yes && ! $DRY_RUN; then
      npm install -g pnpm 2>/dev/null || curl -fsSL https://get.pnpm.io/install.sh | sh -
      print_success "pnpm installed"
    else
      print_skip "pnpm skipped"
    fi
  fi
}

# ─── Module: Tmux ────────────────────────────────────────────────────────────
mod_tmux() {
  print_header "Tmux"

  if ! command -v tmux &>/dev/null; then
    print_add "tmux not found"
    if ask_apply; then
      brew install tmux
      print_success "tmux installed"
    fi
  else
    print_success "tmux ($(tmux -V))"
  fi

  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    print_success "TPM (tmux plugin manager)"
  else
    print_add "TPM not found (will clone)"
    if ask_apply; then
      git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
      print_success "TPM cloned — open tmux and press prefix + I to install plugins"
    fi
  fi
}

# ─── Module: Claude Code ─────────────────────────────────────────────────────

_install_brew_pkg() {
  local pkg="$1"
  if command -v "$pkg" &>/dev/null; then
    print_success "$pkg"
  else
    print_add "$pkg (will install via brew)"
    if ask_apply; then
      brew install "$pkg" && print_success "$pkg installed"
    fi
  fi
}

_install_brew_tap_pkg() {
  local tap="$1"
  local cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    print_success "$cmd"
  else
    print_add "$cmd (will install via brew tap $tap)"
    if ask_apply; then
      brew install "$tap" && print_success "$cmd installed"
    fi
  fi
}

_install_uv_tool() {
  local pkg="$1"
  local cmd="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    print_success "$cmd"
  else
    print_add "$cmd (will install via uv tool)"
    if ask_apply; then
      uv tool install "$pkg" && print_success "$cmd installed"
    fi
  fi
}

_install_cargo_crate() {
  local crate="$1"
  local cmd="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    print_success "$cmd"
  else
    print_add "$cmd (will install via cargo)"
    if ask_apply; then
      cargo install "$crate" && print_success "$cmd installed"
    fi
  fi
}

_install_pnpm_global() {
  local pkg="$1"
  local cmd="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    print_success "$cmd"
  else
    print_add "$cmd (will install via pnpm)"
    if ask_apply; then
      pnpm add -g "$pkg" && print_success "$cmd installed"
    fi
  fi
}

mod_claude() {
  print_header "Claude Code"

  # --- Symlink config files into ~/.claude/ ---
  mkdir -p "$HOME/.claude" "$HOME/.claude/agents"

  local claude_files=(CLAUDE.md settings.json statusline.sh enforce-package-manager.sh)
  for item in "${claude_files[@]}"; do
    _apply_symlink "$DOTFILES_DIR/claude/$item" "$HOME/.claude/$item" "~/.claude/$item"
  done
  _apply_symlink "$DOTFILES_DIR/claude/agents/principal-code-reviewer.md" \
    "$HOME/.claude/agents/principal-code-reviewer.md" \
    "~/.claude/agents/principal-code-reviewer.md"

  # --- Install dev tool prerequisites ---
  print_info "Checking dev tool prerequisites..."

  # Brew packages
  if command -v brew &>/dev/null; then
    _install_brew_pkg ast-grep
    _install_brew_pkg shellcheck
    _install_brew_pkg shfmt
    _install_brew_pkg actionlint
    _install_brew_pkg zizmor
    _install_brew_tap_pkg macos-trash trash
    _install_brew_tap_pkg timvw/tap/wt wt
  else
    print_warn "Homebrew not available — skipping brew packages"
  fi

  # Python tools (via uv)
  if command -v uv &>/dev/null; then
    _install_uv_tool ruff
    _install_uv_tool ty
    _install_uv_tool pip-audit
  else
    print_warn "uv not available — skipping Python tools"
  fi

  # Cargo crates
  if command -v cargo &>/dev/null; then
    _install_cargo_crate prek
    _install_cargo_crate cargo-deny
    _install_cargo_crate cargo-careful
  else
    print_warn "cargo not available — skipping Rust tools"
  fi

  # Node tools (via pnpm)
  if command -v pnpm &>/dev/null; then
    _install_pnpm_global oxlint
  else
    print_warn "pnpm not available — skipping Node tools"
  fi
}

# ─── Module: macOS defaults ─────────────────────────────────────────────────
mod_macos() {
  print_header "macOS Defaults"

  if [[ "$(uname)" != "Darwin" ]]; then
    print_warn "Not macOS — skipping"
    return
  fi

  print_info "Will run tools/macos-defaults.sh to set macOS defaults (requires sudo)"
  print_info "Categories: General UI, Keyboard, Screen, Finder, Dock, Terminal, Activity Monitor, TextEdit, Chrome, Mail"

  ask_for_confirmation "Apply macOS defaults?"
  if answer_is_yes && ! $DRY_RUN; then
    bash "$DOTFILES_DIR/tools/macos-defaults.sh"
    print_success "macOS defaults applied"
  else
    print_skip "macOS defaults skipped"
  fi
}

# ─── Reverse sync ───────────────────────────────────────────────────────────
mod_reverse() {
  print_header "Reverse Sync (system -> dotfiles)"

  if ! command -v brew &>/dev/null; then
    print_error "Homebrew not installed — skipping"
    return
  fi

  local brewfile="$DOTFILES_DIR/tools/Brewfile"

  # Snapshot: Brewfile wants vs installed leaves
  local tmp_wanted tmp_installed
  tmp_wanted="$(mktemp)"
  tmp_installed="$(mktemp)"
  trap "rm -f '$tmp_wanted' '$tmp_installed'" RETURN

  sed -n 's/^brew "\([^"]*\)".*/\1/p' "$brewfile" | sort > "$tmp_wanted"
  brew leaves 2>/dev/null | sort > "$tmp_installed"

  # Find extras (installed but not in Brewfile)
  local -a extras=()
  while IFS= read -r pkg; do
    extras+=("$pkg")
  done < <(comm -23 "$tmp_installed" "$tmp_wanted")

  if [[ ${#extras[@]} -eq 0 ]]; then
    print_success "No extra brew packages found"
  else
    print_info "${#extras[@]} package(s) installed but not in Brewfile:"
    for pkg in "${extras[@]}"; do
      print_warn "$pkg"
    done

    ask_for_confirmation "Add these to Brewfile?"
    if answer_is_yes && ! $DRY_RUN; then
      for pkg in "${extras[@]}"; do
        echo "brew \"$pkg\"" >> "$brewfile"
        print_add "Added $pkg to Brewfile"
      done
      print_info "Review changes:"
      (cd "$DOTFILES_DIR" && git diff Brewfile)
    fi
  fi
}

# ─── Status mode ────────────────────────────────────────────────────────────
show_status() {
  print_header "Status Overview"

  # Xcode CLT
  if xcode-select -p &>/dev/null; then
    print_success "Xcode CLT"
  else
    print_warn "Xcode CLT not installed"
  fi

  # Homebrew
  if command -v brew &>/dev/null; then
    print_success "Homebrew"
  else
    print_warn "Homebrew not installed"
  fi

  # Symlinks
  local ok=0 missing=0 wrong=0
  for item in "${SYMLINK_FILES[@]}"; do
    local target="$HOME/$item"
    local source="$DOTFILES_DIR/configs/$item"
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
      ((ok++))
    elif [[ -e "$target" ]]; then
      ((wrong++))
    else
      ((missing++))
    fi
  done
  for item in "${SYMLINK_DIRS[@]}"; do
    local target="$HOME/$item"
    local source="$DOTFILES_DIR/$item"
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
      ((ok++))
    elif [[ -e "$target" ]]; then
      ((wrong++))
    else
      ((missing++))
    fi
  done
  if [[ $missing -eq 0 && $wrong -eq 0 ]]; then
    print_success "Symlinks ($ok OK)"
  else
    print_warn "Symlinks ($ok OK, $missing missing, $wrong wrong)"
  fi

  # Oh My Zsh
  if [[ -d "$DOTFILES_DIR/.oh-my-zsh" ]]; then
    print_success "Oh My Zsh"
  else
    print_warn "Oh My Zsh not installed"
  fi

  # Neovim
  if command -v nvim &>/dev/null; then
    print_success "neovim ($(nvim --version | head -1))"
  else
    print_warn "neovim not installed"
  fi

  # Key tools
  for tool in bat eza fd fzf rg delta zoxide git gh node pyenv cargo gcloud pnpm; do
    if command -v "$tool" &>/dev/null; then
      print_success "$tool"
    else
      print_warn "$tool not found"
    fi
  done
}

# ─── Module: LLM CLI ────────────────────────────────────────────────────────
mod_llm() {
  print_header "LLM CLI"

  if ! command -v llm &>/dev/null; then
    print_warn "llm not installed — run the brew module first"
    return
  fi

  print_success "llm $(llm --version 2>/dev/null)"

  # Detect configured keys via the keys file
  local keys_file
  keys_file="$(llm keys path 2>/dev/null)"
  local configured_keys=()
  if [[ -f "$keys_file" ]]; then
    while IFS= read -r key; do
      [[ -n "$key" ]] && configured_keys+=("$key")
    done < <(python3 -c "
import json, sys
try:
    d = json.loads(open('$keys_file').read())
    print('\n'.join(d.keys()))
except Exception:
    pass
" 2>/dev/null)
  fi

  if [[ ${#configured_keys[@]} -gt 0 ]]; then
    print_success "Configured keys: ${configured_keys[*]}"
    echo ""
    ask_for_confirmation "Set up an additional provider?"
    answer_is_yes || return
  else
    print_add "No API keys configured yet"
  fi

  echo ""
  print_info "Choose a provider to configure:"
  printf "    %s\n" \
    "1) OpenAI      (gpt-4o, no plugin needed)" \
    "2) Anthropic   (claude-3.5-sonnet, plugin: llm-anthropic)" \
    "3) Gemini      (gemini-1.5-flash, plugin: llm-gemini)" \
    "4) Mistral     (mistral-large, plugin: llm-mistral)" \
    "5) Skip"
  echo ""
  printf "${YELLOW}  [?] Select [1-5]: ${NC}"
  read -rn 1 choice
  printf "\n\n"

  local plugin="" key_name="" provider_name=""
  case "$choice" in
    1) provider_name="OpenAI";    plugin="";              key_name="openai"    ;;
    2) provider_name="Anthropic"; plugin="llm-anthropic"; key_name="anthropic" ;;
    3) provider_name="Gemini";    plugin="llm-gemini";    key_name="gemini"    ;;
    4) provider_name="Mistral";   plugin="llm-mistral";   key_name="mistral"   ;;
    *) print_skip "LLM setup skipped"; return ;;
  esac

  # Install plugin if needed
  if [[ -n "$plugin" ]]; then
    if llm plugins 2>/dev/null | grep -q "\"$plugin\""; then
      print_success "$plugin already installed"
    else
      print_add "Installing ${plugin}..."
      if ! $DRY_RUN; then
        llm install "$plugin" && print_success "$plugin installed"
      fi
    fi
  fi

  # Check if this key is already set
  if [[ ${#configured_keys[@]} -gt 0 ]] && printf '%s\n' "${configured_keys[@]}" | grep -qx "$key_name"; then
    print_success "$provider_name key already set"
    ask_for_confirmation "Replace it?"
    answer_is_yes || return
  fi

  # Prompt for key (hidden input)
  printf "${YELLOW}  [?] $provider_name API key (hidden): ${NC}"
  read -rs api_key
  printf "\n"

  if [[ -z "$api_key" ]]; then
    print_warn "No key entered — skipping"
    return
  fi

  if ! $DRY_RUN; then
    printf '%s' "$api_key" | llm keys set "$key_name"
    print_success "$provider_name API key saved"
  fi
}

# ─── Run modules ────────────────────────────────────────────────────────────

ALL_MODULES=(xcode homebrew brewpkgs symlinks omz shell-tools nvim toolchains llm tmux claude macos)

run_module() {
  case "$1" in
    xcode)        mod_xcode ;;
    homebrew)     mod_homebrew ;;
    brewpkgs|brew) mod_brewpkgs ;;
    symlinks)     mod_symlinks ;;
    omz)          mod_omz ;;
    shell-tools)  mod_shell_tools ;;
    nvim|vim)     mod_vim ;;
    toolchains)   mod_toolchains ;;
    llm)          mod_llm ;;
    tmux)         mod_tmux ;;
    claude)       mod_claude ;;
    macos)        mod_macos ;;
    *) print_error "Unknown module: $1"; exit 1 ;;
  esac
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  Dotfiles Setup — $(date +%Y-%m-%d)"
  echo "  $DOTFILES_DIR"
  echo ""

  if $DRY_RUN; then
    print_info "DRY RUN — no changes will be made"
    echo ""
  fi

  if $STATUS_MODE; then
    show_status
    exit 0
  fi

  if $REVERSE_MODE; then
    mod_reverse
    exit 0
  fi

  if [[ -n "$SINGLE_MODULE" ]]; then
    run_module "$SINGLE_MODULE"
    exit 0
  fi

  for mod in "${ALL_MODULES[@]}"; do
    run_module "$mod"
  done

  echo ""
  print_success "All done!"
  echo ""
}

main
