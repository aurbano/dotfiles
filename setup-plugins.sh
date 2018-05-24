#!/bin/bash

# Install the Pure prompt
npm install --global pure-prompt

# Install Oh My Zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

# Install Z completion for OMZ
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install pygments for colorized cat (ccat)
sudo easy_install Pygments

