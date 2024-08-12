# This where you typically mount your home directory
# but it can be overwritten
if [ -z "$MNT" ]; then
    export MNT=$HOME/mnt
fi

>>>>>>> f50fc3c (MNT variable)
# Create a symbolic link to some mounted files

# This is our github copilot hosts file
mkdir -p ~/.config/github-copilot
ln -s $MNT/.config/github-copilot/hosts.json ~/.config/github-copilot/hosts.json
