#!/usr/bin/env bash
set -euo pipefail

# ─── Dotfiles update ────────────────────────────────────────────────────────
# Periodic upkeep: refreshes every updatable surface the dotfiles manage.
# Complement to setup.sh, which is for first-time provisioning.
#
# Usage:
#   ./update.sh                   # Non-interactive, run every module
#   ./update.sh --dry-run         # Print planned actions, change nothing
#   ./update.sh --module NAME     # Run a single module
#   ./update.sh -h | --help

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

DRY_RUN=false
SINGLE_MODULE=""
FAILED_MODULES=()

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header()  { printf "\n${PURPLE}=== %s ===${NC}\n\n" "$1"; }
print_success() { printf "${GREEN}  [=] %s${NC}\n" "$1"; }
print_warn()    { printf "${YELLOW}  [!] %s${NC}\n" "$1"; }
print_error()   { printf "${RED}  [✖] %s${NC}\n" "$1"; }
print_info()    { printf "${BLUE}  [i] %s${NC}\n" "$1"; }
print_skip()    { printf "  [-] %s\n" "$1"; }

# Run a command unless in dry-run mode. Prints the command either way.
run() {
  print_info "\$ $*"
  if $DRY_RUN; then return 0; fi
  "$@"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --module)  SINGLE_MODULE="${2:-}"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./update.sh [--dry-run] [--module NAME]

Modules (run in order by default):
  brew         brew update, upgrade, cleanup, bundle
  nvim         lazy.nvim sync + treesitter parser updates
  omz          git pull Oh My Zsh core + each custom plugin
  tmux         TPM update_plugins all
  toolchains   rustup, uv tools, pnpm globals, fnm LTS
EOF
      exit 0 ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# ─── Module: Homebrew ───────────────────────────────────────────────────────
mod_brew() {
  print_header "Homebrew"

  if ! command -v brew &>/dev/null; then
    print_warn "brew not found — skipping"
    return
  fi

  run brew update
  run brew upgrade
  run brew cleanup -s

  local brewfile="$DOTFILES_DIR/tools/Brewfile"
  if [[ -f "$brewfile" ]]; then
    run brew bundle --file="$brewfile"
  else
    print_warn "Brewfile not found at $brewfile — skipping bundle"
  fi
}

# ─── Module: Neovim ─────────────────────────────────────────────────────────
mod_nvim() {
  print_header "Neovim"

  if ! command -v nvim &>/dev/null; then
    print_warn "nvim not found — skipping"
    return
  fi

  run nvim --headless "+Lazy! sync" +qa
  run nvim --headless "+TSUpdateSync" +qa
}

# ─── Module: Oh My Zsh + custom plugins ─────────────────────────────────────
_pull_repo() {
  local dir="$1"
  local label="$2"
  if [[ ! -d "$dir/.git" ]]; then
    print_skip "$label (not a git repo)"
    return
  fi
  if $DRY_RUN; then
    print_info "\$ git -C $dir pull --ff-only --quiet"
    return
  fi
  if git -C "$dir" pull --ff-only --quiet; then
    print_success "$label"
  else
    print_error "$label (pull failed)"
    return 1
  fi
}

mod_omz() {
  print_header "Oh My Zsh + custom plugins"

  local omz_dir="$DOTFILES_DIR/.oh-my-zsh"
  if [[ ! -d "$omz_dir" ]]; then
    print_warn "Oh My Zsh not installed at $omz_dir — skipping"
    return
  fi

  _pull_repo "$omz_dir" "oh-my-zsh"

  local plugin_dir="$omz_dir/custom/plugins"
  if [[ ! -d "$plugin_dir" ]]; then
    return
  fi

  for plugin in "$plugin_dir"/*/; do
    [[ -d "$plugin" ]] || continue
    _pull_repo "${plugin%/}" "$(basename "$plugin")"
  done
}

# ─── Module: Tmux plugins (TPM) ─────────────────────────────────────────────
mod_tmux() {
  print_header "Tmux plugins (TPM)"

  local tpm_update="$HOME/.tmux/plugins/tpm/bin/update_plugins"
  if [[ ! -x "$tpm_update" ]]; then
    print_warn "TPM not installed at $tpm_update — skipping"
    return
  fi

  run "$tpm_update" all
}

# ─── Module: Language toolchains ────────────────────────────────────────────
mod_toolchains() {
  print_header "Toolchains"

  if command -v rustup &>/dev/null; then
    run rustup update
  else
    print_skip "rustup not found"
  fi

  if command -v uv &>/dev/null; then
    run uv tool upgrade --all
  else
    print_skip "uv not found"
  fi

  if command -v pnpm &>/dev/null; then
    run pnpm update -g --latest
  else
    print_skip "pnpm not found"
  fi

  if command -v fnm &>/dev/null; then
    run fnm install --lts
    run fnm default lts-latest
  else
    print_skip "fnm not found"
  fi
}

# ─── Runner ─────────────────────────────────────────────────────────────────
ALL_MODULES=(brew nvim omz tmux toolchains)

run_module() {
  local name="$1"
  case "$name" in
    brew)       mod_brew ;;
    nvim)       mod_nvim ;;
    omz)        mod_omz ;;
    tmux)       mod_tmux ;;
    toolchains) mod_toolchains ;;
    *) print_error "Unknown module: $name"; exit 1 ;;
  esac
}

# Wrap a module so a failure doesn't abort the whole run.
run_module_safe() {
  local name="$1"
  if ! run_module "$name"; then
    print_error "$name module failed"
    FAILED_MODULES+=("$name")
  fi
}

main() {
  echo ""
  echo "  Dotfiles Update — $(date +%Y-%m-%d)"
  echo "  $DOTFILES_DIR"

  if $DRY_RUN; then
    echo ""
    print_info "DRY RUN — no changes will be made"
  fi

  if [[ -n "$SINGLE_MODULE" ]]; then
    run_module_safe "$SINGLE_MODULE"
  else
    for mod in "${ALL_MODULES[@]}"; do
      run_module_safe "$mod"
    done
  fi

  echo ""
  if [[ ${#FAILED_MODULES[@]} -eq 0 ]]; then
    print_success "All done!"
    exit 0
  else
    print_error "Completed with failures: ${FAILED_MODULES[*]}"
    exit 1
  fi
}

main
