# shell

My personal customed shell as a docker container

# Running

`just run <tag>`

# Terminal Command

This is what to put in your terminal to make it run this container

We mount your home into its ~/mnt directory, and we mount your ~/.ssh into its ~/.ssh so that you can access things like github and other machines, etc.

```bash
docker run -it --rm -v <YOUR_HOME>/.ssh:/home/rgpeach10/.ssh -v <YOUR_HOME>:/home/rgpeach10/mnt -w /home/rgpeach10/mnt --pull=always rgpeach10/shell:main
```

# Private Info

Create a `.zshrc.private` in your home directory to add private information to your shell

Example:

```bash
git config --global user.email "<email>"
git config --global user.name "<name>"
```
