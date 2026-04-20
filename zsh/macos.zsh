# ─── macOS conveniences ──────────────────────────────────────────────────────
# Ported subset of ohmyzsh/plugins/macos.

# Open in Finder: current directory if no args, else each argument.
ofd() {
  if (( ! $# )); then
    open "$PWD"
  else
    open "$@"
  fi
}

# Toggle hidden files in Finder.
alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Open a new terminal tab in the current directory. Supports Ghostty + common
# alternatives so this keeps working across terminal swaps.
_macos_frontmost_app() {
  osascript 2>/dev/null <<EOF
    tell application "System Events"
      name of first item of (every process whose frontmost is true)
    end tell
EOF
}

tab() {
  local command="cd \\\"$PWD\\\"; clear"
  (( $# > 0 )) && command="${command}; $*"

  local the_app
  the_app=$(_macos_frontmost_app)

  case "$the_app" in
    ghostty)
      osascript >/dev/null <<EOF
        tell application "System Events"
          tell process "Ghostty" to keystroke "t" using command down
        end tell
EOF
      ;;
    Terminal)
      osascript >/dev/null <<EOF
        tell application "System Events"
          tell process "Terminal" to keystroke "t" using command down
        end tell
        tell application "Terminal" to do script "${command}" in front window
EOF
      ;;
    iTerm2)
      osascript <<EOF
        tell application "iTerm2"
          tell current window
            create tab with default profile
            tell current session to write text "${command}"
          end tell
        end tell
EOF
      ;;
    *)
      echo "tab: unsupported terminal app: $the_app" >&2
      return 1
      ;;
  esac
}
