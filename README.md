# shell

My personal customed shell as a docker container

# Install in Terminal

## Install Nerdfonts

Do this in your terminal, not in the container

```bash
git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
./install.sh
```

Or you can just install one.

Currently I've tested this with `JetBrainsMono Nerd Font`

## Private Info

Create a `.zshrc.private` in your home directory to add private information to your shell

Example:

```bash
git config --global user.email "<email>"
git config --global user.name "<name>"
```

## Get your Terminal to launch from the container

Create a `~/.docker-shell.sh` file with the following contents:

```bash
#!/usr/bin/env bash

docker run -it --rm \
    -v $HOME/.ssh:/home/root/.ssh \
    -v $HOME:/home/root/mnt \
    -w /home/root/mnt \
    -e GITHUB_TOKEN=$(gh auth token) \
    -e MNT=/home/rgpeach10/mnt \
    --pull=always \
    rgpeach10/shell:main
```

Then set your terminal to launch this script when you open it.

Or you could put it in your `~/.bash_profile`, `~/.bashrc`, or `~/.zshrc` file.

It's important the MNT variable is set to the directory you want to mount your home in the container from the containers filesystem perspective.

# Editing this repo from within this container

It is best to clone THIS REPO into your home directory

`git clone git@github.com:ryanpeach/shell.git $HOME/shell`

The `.zshrc` will detect this directory mounted to $SHELL_MNT_DIR which defaults to $HOME/mnt/shell inside the container, and stow files from its ./home directory.

This will allow you to safely edit your config from within your docker container, even within multiple running instances.

# If you want to use this zshrc file and other configs on your local!

Just make a `.zprofile` that looks like this

```bash
export ZSH_PRIVATE_LOC=$HOME/.zshrc.private.local
export MNT=$HOME
```

And make a `$HOME/.zshrc.private.local` (like your `$HOME/.zshrc.private` but will only be sourced by your local copy of the zshrc file) 

If you have nothing Docker Container specific (and usually even if you do), this can just say:

```bash
source $HOME/.zshrc.private
```

A reason you might put something in here that's NOT in your `.zshrc.private` is if you have an os-specific command that you would run privately but WOULD NOT want to run in the container.

In general, `if [[ $IS_DOCKER ]]` this repo will assume you are running in the container.

Now, `stow home`

IF YOU WANT TO GET RID OF YOUR LOCAL CONFIGS IN FAVOR OF THOSE IN THIS REPO

```bash
stow --adopt home
git reset HEAD --hard
```

# Running from the Repo

`just run <tag>`

Should do almost everything you need to do to run this container mounting the home directory and getting `git` and `gh` to work. The rest are just understanding the commands and what they do.

# Design Information

## Getting GH and Git to work

Log in to gh in your normal terminal using

```bash
gh auth login
```

Choose SSH auth

This will guide you through some steps,
and create a token in your ~/.config/gh directory,
as well as add your ssh key to your github account.

Now you just need to add to your `docker run` command:

`-v <YOUR_HOME>/.ssh:/home/root/.ssh` for ssh keys

And

`-e GITHUB_TOKEN=$(gh auth token)` for the github token
