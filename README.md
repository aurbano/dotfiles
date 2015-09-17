This are my personal dotfiles, and probably won't work out of the box for you.

If you want your own dotfiles, I'd recommend following [@Paul Irish's](https://github.com/paulirish/dotfiles) guide, he's written great documentation.

My vim settings and plugins have been extended from his, so if you use vim a lot it might be worth using this version.

## Getting started

```bash
$ git clone https://github.com/aurbano/dotfiles.git ~/dotfiles
```

### Vim

First install vim & dependencies

```bash
$ brew install vim          # Mac OSX
$ sudo apt-get install vim  # Linux (Ubuntu...)
$ sudo yum install vim      # Linux (CentOS, Fedora, Red Hat...)
```
Install vim plugin managers:

```bash
# vundle
$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
# pathogen
$ mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
```

```bash
$ ln -s ~/dotfiles/.vim ~/.vim
$ ln -s ~/dotfiles/.vimrc ~/.vimrc
```

Now open vim, and run

```
:PluginInstall
:PlugInstall
```

This will install the rest of the plugins for you. Then restart vim.

In order to get the right looks you need a [powerline enabled font](https://github.com/powerline/fonts).

### Everything else
The rest of the things are optional and depend on what you need. There are some scripts that automate mostly everything, so maybe open them, decide which parts you like, and delete/comment out the rest:

* `brew.sh` & `brew-cask` for Mac OSX, installs useful tools
*  `.osx` Sets up your Mac's preferences
*  `setup-a-new-machine.sh` this does a lot of things, so approach with caution, open the script and take a look before running.
*  `symlink-setup.sh` automatically symlink things from the dotfiles directory to your home directory. Probably safe to run.

Careful with the `.gitconfig`, make sure to add in your username/email in there.
