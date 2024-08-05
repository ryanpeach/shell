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
    -v $HOME/.ssh:/home/rgpeach10/.ssh \
    -v $HOME:/home/rgpeach10/mnt \
    -w /home/rgpeach10/mnt \
    -e GITHUB_TOKEN=$(gh auth token) \
    --pull=always \
    rgpeach10/shell:main
```

Then set your terminal to launch this script when you open it.

Or you could put it in your `~/.bash_profile`, `~/.bashrc`, or `~/.zshrc` file.

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

`-v <YOUR_HOME>/.ssh:/home/rgpeach10/.ssh` for ssh keys

And

`-e GITHUB_TOKEN=$(gh auth token)` for the github token
