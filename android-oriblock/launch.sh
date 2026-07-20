#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Root required!"
    exit 1
fi

HOSTS="/data/adb/modules/systemless-hosts/system/etc/hosts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$SCRIPT_DIR/list-general.txt"

if [ ! -f "$LIST" ]; then
    echo "[!] list-general.txt не найден в: $SCRIPT_DIR"
    exit 1
fi

COUNT=0
while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    domain="$(echo "$line" | xargs)"
    [ -z "$domain" ] && continue
    
    if ! grep -qF "127.0.0.1 $domain" "$HOSTS"; then
        echo "127.0.0.1 $domain" >> "$HOSTS"
        # grep -qF "127.0.0.1 www.$domain" "$HOSTS" || echo "127.0.0.1 www.$domain" >> "$HOSTS"
        ((COUNT++))
    fi
done < "$LIST"

echo "ORI-Block enabled"
echo "[+] Blocked domains: $COUNT"
sleep 2
exit 0
