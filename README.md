# shell

My personal customed shell as a docker container

# Running

`just run <tag>`

Should do almost everything you need to do to run this container mounting the home directory and getting `git` and `gh` to work. The rest are just understanding the commands and what they do.

# Terminal Command

This is what to put in your terminal to make it run this container

We mount your home into its ~/mnt directory, and we mount your ~/.ssh into its ~/.ssh so that you can access things like github and other machines, etc.

```bash
docker run -it --rm -v $HOME:/home/rgpeach10/mnt -w /home/rgpeach10/mnt --pull=always rgpeach10/shell:main
```

# Private Info

Create a `.zshrc.private` in your home directory to add private information to your shell

Example:

```bash
git config --global user.email "<email>"
git config --global user.name "<name>"
```

# Getting GH and Git to work

Log in to gh in your normal terminal using

```bash
gh auth login --insecure-storage
```

Choose SSH auth

This will guide you through some steps,
and create a token in your ~/.config/gh directory,
as well as add your ssh key to your github account.

Now you just need to add to your `docker run` command:

`-v <YOUR_HOME>/.ssh:/home/rgpeach10/.ssh` for ssh keys

And

`-v <YOUR_HOME>/.config/gh:/home/rgpeach10/.config/gh` for the gh token

Totalling to

```bash
docker run -it --rm \
  -v $HOME/.ssh:/home/rgpeach10/.ssh \
  -v $HOME/.config/gh:/home/rgpeach10/.config/gh \
  -v $HOME:/home/rgpeach10/mnt \
  -w /home/rgpeach10/mnt \
  --pull=always \
  rgpeach10/shell:main
```
