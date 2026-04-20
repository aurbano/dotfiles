# ─── Git shell aliases ──────────────────────────────────────────────────────
# Curated subset of ohmyzsh/plugins/git. Trimmed to the commonly-used shortcuts;
# extend as needed. `.gitconfig` aliases (s, c, up, p, lg, ...) still apply, so
# combinations like `g s` work (→ `git status`).

git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/heads/{main,trunk,mainline,default,master} refs/remotes/{origin,upstream}/{main,trunk,mainline,default,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref##*/}
      return
    fi
  done
  echo master
}

alias g='git'

# add
alias ga='git add'
alias gaa='git add --all'
alias gap='git add --patch'

# branch
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'

# checkout / switch
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'
alias gsw='git switch'
alias gswc='git switch --create'

# commit
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias gcam='git commit --all --message'
alias gcmsg='git commit --message'
alias gcn='git commit --verbose --no-edit'
alias gcan!='git commit --verbose --all --amend --no-edit'

# diff
alias gd='git diff'
alias gds='git diff --staged'
alias gdca='git diff --cached'

# fetch
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'

# log
alias gl='git pull'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

# push
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpo='git push origin'
alias gpoat='git push origin --all && git push origin --tags'

# rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'

# reset / restore
alias gr='git reset'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'

# status
alias gs='git status'
alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

# stash
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gstd='git stash drop'

# clone
alias gcl='git clone --recurse-submodules'

# cd to repo root
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
