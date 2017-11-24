# uncomment to profile prompt startup with zprof
# zmodload zsh/zprof

# history
SAVEHIST=100000

# vim bindings
bindkey -v

fpath=( "$HOME/.zfunctions" $fpath )

export PATH="/usr/local/sbin:$PATH"

# antigen time!
source ~/code/antigen/antigen.zsh


######################################################################
### install some antigen bundles

local b="antigen-bundle"


# Don't load the oh-my-zsh's library. Takes too long. No need.
	# antigen use oh-my-zsh

# Guess what to install when running an unknown command.
$b command-not-found

# Helper for extracting different types of archives.
$b extract

# homebrew  - autocomplete on `brew install`
$b brew
$b brew-cask

# Tracks your most used directories, based on 'frecency'.
$b robbyrussell/oh-my-zsh plugins/z

# suggestion as you type
$b tarruda/zsh-autosuggestions

# nicoulaj's moar completion files for zsh
# $b zsh-users/zsh-completions src

# Syntax highlighting on the readline
$b zsh-users/zsh-syntax-highlighting

# colors for all files!
$b trapd00r/zsh-syntax-highlighting-filetypes

# dont set a theme, because pure does it all
$b mafredri/zsh-async
$b sindresorhus/pure

# history search
$b zsh-users/zsh-history-substring-search

# Tell antigen that you're done.
antigen apply

###
#################################################################################################



# bind UP and DOWN arrow keys for history search
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

export PURE_GIT_UNTRACKED_DIRTY=0

# Automatically list directory contents on `cd`.
auto-ls () {
	emulate -L zsh;
	# explicit sexy ls'ing as aliases arent honored in here.
	hash gls >/dev/null 2>&1 && CLICOLOR_FORCE=1 gls -aFh --color --group-directories-first || ls
}
chpwd_functions=( auto-ls $chpwd_functions )

# history mgmt
# http://www.refining-linux.org/archives/49/ZSH-Gem-15-Shared-history/
setopt inc_append_history
setopt share_history


zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'


# uncomment to finish profiling
# zprof



# Load default dotfiles
source ~/.bash_profile

export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/Library/Python/2.7/bin:$PATH"

# added by travis gem
[ -f /Users/alex/.travis/travis.sh ] && source /Users/alex/.travis/travis.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
