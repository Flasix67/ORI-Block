#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Permission denied"
    exit 1
fi

HOSTS="/data/adb/modules/systemless-hosts/system/etc/hosts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$SCRIPT_DIR/list-general.txt"

if [ ! -f "$HOSTS" ]; then
    echo "Systemless hosts not found."
    exit 0
fi

if [ ! -f "$LIST" ]; then
    echo "list-general.txt not found"
    exit 1
fi

TEMP_HOSTS=$(mktemp)
PATTERNS=$(mktemp)
cp "$HOSTS" "$TEMP_HOSTS"

while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    domain="$(echo "$line" | xargs)"
    [ -z "$domain" ] && continue
    
    escaped=$(echo "$domain" | sed 's/\./\\./g')
    echo "^127\.0\.0\.1[[:space:]]+${escaped}\$" >> "$PATTERNS"
    echo "^127\.0\.0\.1[[:space:]]+www\.${escaped}\$" >> "$PATTERNS"
done < "$LIST"

if [ -s "$PATTERNS" ]; then
    grep -v -E -f "$PATTERNS" "$TEMP_HOSTS" > "${TEMP_HOSTS}.new"
    mv "${TEMP_HOSTS}.new" "$TEMP_HOSTS"
fi

mv "$TEMP_HOSTS" "$HOSTS"
chmod 644 "$HOSTS"
chown root:root "$HOSTS" 2>/dev/null
rm -f "$PATTERNS"

echo "[+] ORI-Block disabled!"
echo "If domains also dont works try this command:"
echo "su -c setprop ctl.restart netd"
exit 0
