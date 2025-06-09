#!/bin/bash

# Only run as root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Please run this script as root."
  exit 1
fi

CUSTOM_PORT=8088
TARGET_FILE=/var/www/html/index.html
VHOST_CONF=/etc/httpd/conf.d/demo.conf

echo "== [REVERT] Cleaning up custom Apache demo config =="

if [ -f "$VHOST_CONF" ]; then
  rm -f "$VHOST_CONF"
  echo "[+] Removed $VHOST_CONF"
else
  echo "[i] No demo.conf found — already clean"
fi

echo "== [REVERT] Removing test file if it matches demo content =="
if [ -f "$TARGET_FILE" ] && grep -q "Blocked by DAC" "$TARGET_FILE"; then
  rm -f "$TARGET_FILE"
  echo "[+] Removed $TARGET_FILE"
else
  echo "[i] Skipped deleting $TARGET_FILE — it doesn't match test content"
fi

echo "== [REVERT] Removing SELinux port mapping for $CUSTOM_PORT (if exists) =="
if semanage port -l | grep -q "^http_port_t.*$CUSTOM_PORT"; then
  semanage port -d -t http_port_t -p tcp $CUSTOM_PORT
  echo "[+] Removed SELinux port $CUSTOM_PORT from http_port_t"
else
  echo "[i] SELinux port $CUSTOM_PORT already absent"
fi

echo "== [REVERT] Restarting Apache to reload config =="
systemctl restart httpd
sleep 1

echo "== [STATE] SELinux httpd port mappings after cleanup:"
semanage port -l | grep ^http_port_t

echo ""
echo "== [STATE] Apache status:"
systemctl is-active httpd && echo "[✓] httpd is active" || echo "[✗] httpd failed to start"

echo ""
echo "== 🧹 Revert complete — system is back to clean state."

