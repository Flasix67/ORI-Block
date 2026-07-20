#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Permission denied"
    exit 1
fi

HOSTS="/etc/hosts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$SCRIPT_DIR/list-general.txt"

if [ ! -f "$LIST" ]; then
    echo "list-general.txt not found: $SCRIPT_DIR"
    exit 1
fi

TEMP_HOSTS=$(mktemp)
PATTERNS=$(mktemp)

cp "$HOSTS" "$TEMP_HOSTS"

while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ "$clean_line" =~ ^# ]] && continue
    [ -z "$clean_line" ] && continue
    escaped=$(echo "$clean_line" | sed 's/\./\\./g')
    echo "127\.0\.0\.1[[:space:]]+${escaped}([[:space:]]|$)" >> "$PATTERNS"
    echo "127\.0\.0\.1[[:space:]]+www\.${escaped}([[:space:]]|$)" >> "$PATTERNS"
done < "$LIST"

if [ -s "$PATTERNS" ]; then
    grep -v -E -f "$PATTERNS" "$TEMP_HOSTS" > "${TEMP_HOSTS}.new" 2>/dev/null || cp "$TEMP_HOSTS" "${TEMP_HOSTS}.new"
    mv "${TEMP_HOSTS}.new" "$TEMP_HOSTS"
fi

mv "$TEMP_HOSTS" "$HOSTS"
chmod 644 "$HOSTS"
chown root:root "$HOSTS"

rm -f "$PATTERNS"

echo "Clearing DNS-cache..."
if systemctl is-active --quiet systemd-resolved; then
    resolvectl flush-caches 2>/dev/null || systemd-resolve --flush-caches 2>/dev/null
elif systemctl is-active --quiet nscd; then
    nscd -i hosts
elif systemctl is-active --quiet dnsmasq; then
    systemctl restart dnsmasq
fi

echo "ORI-Block disabled"
exit 0
