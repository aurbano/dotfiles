#!/bin/bash

# Install command-line tools using Homebrew
brew bundle

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed formulae
brew upgrade

# Clean the cellar
brew cleanup
