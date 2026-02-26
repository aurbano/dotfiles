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
      echo "Modules: xcode, homebrew, brewpkgs, symlinks, omz, shell-tools, vim, toolchains, macos"
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

  local brewfile="$DOTFILES_DIR/Brewfile"
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
  .condarc
  .curlrc
  .dircolors
  .functions
  .gitattributes
  .gitconfig
  .gitignore
  .vimrc
  .zshrc
)
declare -a SYMLINK_DIRS=(
  .vim
  bin
)

mod_symlinks() {
  print_header "Symlinks"

  # Ensure cache dir exists
  mkdir -p ~/.cache/zsh
  touch ~/.cache/zsh/.z

  for item in "${SYMLINK_FILES[@]}" "${SYMLINK_DIRS[@]}"; do
    local source_path="$DOTFILES_DIR/$item"
    local target_path="$HOME/$item"

    if [[ ! -e "$source_path" ]]; then
      print_warn "$item — source missing in dotfiles"
      continue
    fi

    if [[ -L "$target_path" ]]; then
      local current_target
      current_target="$(readlink "$target_path")"
      if [[ "$current_target" == "$source_path" ]]; then
        print_success "~/$item -> $source_path"
      else
        print_warn "~/$item -> $current_target (expected $source_path)"
        if ask_apply; then
          rm -f "$target_path"
          ln -s "$source_path" "$target_path"
          print_success "~/$item -> $source_path (fixed)"
        fi
      fi
    elif [[ -e "$target_path" ]]; then
      print_warn "~/$item exists (regular file, not symlink)"
      ask_for_confirmation "Overwrite ~/$item with symlink?"
      if answer_is_yes && ! $DRY_RUN; then
        rm -rf "$target_path"
        ln -s "$source_path" "$target_path"
        print_success "~/$item -> $source_path (replaced)"
      fi
    else
      print_add "~/$item (will create)"
      if ask_apply; then
        ln -s "$source_path" "$target_path"
        print_success "~/$item -> $source_path (created)"
      fi
    fi
  done

  # Offer to create ~/.zshrc.local from example
  if [[ ! -f "$HOME/.zshrc.local" ]]; then
    print_add "~/.zshrc.local does not exist"
    ask_for_confirmation "Create from .zshrc.local.example?"
    if answer_is_yes && ! $DRY_RUN; then
      cp "$DOTFILES_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
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
  "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
  "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search"
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

  # Note about brew-sourced plugins
  local brew_prefix="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || echo /opt/homebrew)}"
  if [[ -f "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    print_info "zsh-syntax-highlighting also available via brew (sourced in .zshrc)"
  fi
  if [[ -f "$brew_prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    print_info "zsh-history-substring-search also available via brew (sourced in .zshrc)"
  fi
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
      npm install --global pure-prompt 2>/dev/null || brew install pure 2>/dev/null || print_error "Could not install pure prompt"
    fi
  fi

  # Pygments (for colorize plugin)
  if python3 -c "import pygments" 2>/dev/null; then
    print_success "Pygments"
  else
    print_add "Pygments not found (used by colorize plugin)"
    if ask_apply; then
      pip3 install --user Pygments
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

# ─── Module: Vim ─────────────────────────────────────────────────────────────
mod_vim() {
  print_header "Vim"

  local plug_file="$HOME/.vim/autoload/plug.vim"
  if [[ -f "$plug_file" ]]; then
    print_success "vim-plug installed"
  else
    print_add "vim-plug not found (will install)"
    if ask_apply; then
      curl -fLo "$plug_file" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
      print_success "vim-plug installed"
    fi
  fi

  local plugged_dir="$HOME/.vim/plugged"
  if [[ -d "$plugged_dir" ]] && [[ "$(ls -A "$plugged_dir" 2>/dev/null)" ]]; then
    local count
    count="$(ls -1 "$plugged_dir" | wc -l | tr -d ' ')"
    print_success "Vim plugins installed ($count plugins in plugged/)"
  else
    print_add "Vim plugins not installed"
    if ask_apply; then
      vim +PlugInstall +qall
      print_success "Vim plugins installed"
    fi
  fi
}

# ─── Module: Toolchains ─────────────────────────────────────────────────────
mod_toolchains() {
  print_header "Toolchains"

  # NVM
  if [[ -d "$HOME/.nvm" ]] || [[ -s "$(brew --prefix 2>/dev/null)/opt/nvm/nvm.sh" ]]; then
    print_success "NVM"
  else
    print_add "NVM not found"
    ask_for_confirmation "Install NVM?"
    if answer_is_yes && ! $DRY_RUN; then
      brew install nvm
      mkdir -p "$HOME/.nvm"
      print_success "NVM installed"
    else
      print_skip "NVM skipped"
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

# ─── Module: macOS defaults ─────────────────────────────────────────────────
mod_macos() {
  print_header "macOS Defaults"

  if [[ "$(uname)" != "Darwin" ]]; then
    print_warn "Not macOS — skipping"
    return
  fi

  print_info "Will run .osx to set macOS defaults (requires sudo)"
  print_info "Categories: General UI, Keyboard, Screen, Finder, Dock, Terminal, Activity Monitor, TextEdit, Chrome, Mail"

  ask_for_confirmation "Apply macOS defaults?"
  if answer_is_yes && ! $DRY_RUN; then
    bash "$DOTFILES_DIR/.osx"
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

  local brewfile="$DOTFILES_DIR/Brewfile"

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
  for item in "${SYMLINK_FILES[@]}" "${SYMLINK_DIRS[@]}"; do
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

  # Vim plugins
  if [[ -d "$HOME/.vim/plugged" ]] && [[ "$(ls -A "$HOME/.vim/plugged" 2>/dev/null)" ]]; then
    print_success "Vim plugins"
  else
    print_warn "Vim plugins not installed"
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

# ─── Run modules ────────────────────────────────────────────────────────────

ALL_MODULES=(xcode homebrew brewpkgs symlinks omz shell-tools vim toolchains macos)

run_module() {
  case "$1" in
    xcode)        mod_xcode ;;
    homebrew)     mod_homebrew ;;
    brewpkgs|brew) mod_brewpkgs ;;
    symlinks)     mod_symlinks ;;
    omz)          mod_omz ;;
    shell-tools)  mod_shell_tools ;;
    vim)          mod_vim ;;
    toolchains)   mod_toolchains ;;
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
