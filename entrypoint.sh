#!/bin/sh
set -e

TARGET_UID=${TARGET_UID:-1000}
TARGET_GID=${TARGET_GID:-1000}
USERNAME=${USERNAME:-rgpeach10}

CURRENT_UID=$(id -u "$USERNAME")
CURRENT_GID=$(id -g "$USERNAME")

# Rewrite the user/group IDs if they differ from build time
if [ "$CURRENT_UID" != "$TARGET_UID" ] || [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    sed -i "s/^$USERNAME:x:$CURRENT_UID:$CURRENT_GID:/$USERNAME:x:$TARGET_UID:$TARGET_GID:/" /etc/passwd
    sed -i "s/^$USERNAME:x:$CURRENT_GID:/$USERNAME:x:$TARGET_GID:/" /etc/group
    chown "$TARGET_UID:$TARGET_GID" "/home/$USERNAME"
    ITEMS=$(find "/home/$USERNAME" -mindepth 1 -maxdepth 1 ! -name mnt)
    TOTAL=$(printf '%s\n' "$ITEMS" | wc -l)
    I=0
    printf '%s\n' "$ITEMS" | while read -r item; do
        I=$((I + 1))
        printf '\r\033[Kchown [%d/%d] %s' "$I" "$TOTAL" "${item##*/}"
        chown -R "$TARGET_UID:$TARGET_GID" "$item"
    done
    printf '\r\033[Kchown complete (%d items)\n' "$TOTAL"
fi

exec su - "$USERNAME" -s /bin/zsh -c "$*"
