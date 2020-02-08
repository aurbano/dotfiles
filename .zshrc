# Path to your oh-my-zsh installation.
export ZSH=~/dotfiles/.oh-my-zsh

# Pure prompt
autoload -U promptinit; promptinit

# Improve autocompletion, changing the cache path
fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit -d ~/.cache/zsh/.zcompdump-$ZSH_VERSION 

# Set name of the theme to load
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="" # Empty for pure prompt

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd.mm.yyyy"
export HISTFILE="~/.cache/.zsh_history"

# Change z storage dir
export _Z_DATA="$HOME/.cache/zsh/.z"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  aws
  colored-man-pages
  colorize
  command-not-found
  common-aliases
  docker
  git
  golang
  gradle
  gulp
  heroku
  iterm2
  npm
  osx
  ssh-agent
  sudo
  yarn
  z
  zsh-history-substring-search
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting # keep this one last!
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
source ~/dotfiles/.functions
source ~/dotfiles/.aliases

# added by travis gem
[ -f /Users/alex/.travis/travis.sh ] && source /Users/alex/.travis/travis.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Setup golang
export GOPATH=~/proyects/golang

# Android Emulator
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Add pure as the prompt at the end, so it can override oh my zsh
prompt pure

export PATH=/Users/alex/.local/bin:$PATH
