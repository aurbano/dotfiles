#!/bin/bash

# Install the Pure prompt
npm install --global pure-prompt

# Install Oh My Zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/dotfiles/.oh-my-zsh
ln -s ~/dotfiles/.oh-my-zsh ~/.oh-my-zsh

# Oh My Zsh Additional plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

# Install pygments for colorized cat (ccat)
sudo easy_install Pygments

