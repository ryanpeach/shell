#!/bin/sh
set -e

TARGET_UID=${TARGET_UID:-1000}
TARGET_GID=${TARGET_GID:-1000}
USERNAME=rgpeach10

CURRENT_UID=$(id -u "$USERNAME")
CURRENT_GID=$(id -g "$USERNAME")

# Rewrite the user/group IDs if they differ from build time
if [ "$CURRENT_UID" != "$TARGET_UID" ] || [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    sed -i "s/^$USERNAME:x:$CURRENT_UID:$CURRENT_GID:/$USERNAME:x:$TARGET_UID:$TARGET_GID:/" /etc/passwd
    sed -i "s/^$USERNAME:x:$CURRENT_GID:/$USERNAME:x:$TARGET_GID:/" /etc/group
    chown -R "$TARGET_UID:$TARGET_GID" "/home/$USERNAME"
fi

exec su - "$USERNAME" -s /bin/zsh -c "$*"
