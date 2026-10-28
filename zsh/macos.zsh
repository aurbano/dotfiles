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

# Quote a string for an AppleScript literal: escape backslashes and quotes.
_applescript_quote() {
  local s=${1//\\/\\\\}
  print -r -- "\"${s//\"/\\\"}\""
}

tab() {
  local dir=$(_applescript_quote "$PWD")
  local cmd=$(_applescript_quote "$*")
  local shell_cmd=$(_applescript_quote "cd ${(q)PWD}; clear${*:+; $*}")

  local the_app
  the_app=$(_macos_frontmost_app)

  case "$the_app" in
    ghostty)
      osascript >/dev/null <<EOF
        tell application "Ghostty"
          set cfg to new surface configuration
          set initial working directory of cfg to ${dir}
          if ${cmd} is not "" then set initial input of cfg to ${cmd} & linefeed
          new tab in front window with configuration cfg
        end tell
EOF
      ;;
    Terminal)
      osascript >/dev/null <<EOF
        tell application "System Events"
          tell process "Terminal" to keystroke "t" using command down
        end tell
        tell application "Terminal" to do script ${shell_cmd} in front window
EOF
      ;;
    iTerm2)
      osascript >/dev/null <<EOF
        tell application "iTerm2"
          tell current window
            create tab with default profile
            tell current session to write text ${shell_cmd}
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
