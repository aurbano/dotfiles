[ -n "$PS1" ] && source ~/.bash_profile

# added by travis gem
[ -f /Users/alex/.travis/travis.sh ] && source /Users/alex/.travis/travis.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
