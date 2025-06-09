#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Run this script as root."
  exit 1
fi

CUSTOM_PORT=8088
DEMO_DIR=~/selinux_demo
DEMO_FILE=$DEMO_DIR/index.html
TARGET_FILE=/var/www/html/index.html
VHOST_CONF=/etc/httpd/conf.d/demo.conf
USER_NAME=$(logname)

# gasuftaveba
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR"
rm -f "$TARGET_FILE"
rm -f "$VHOST_CONF"

# sademonstracio faili sheqmna 
echo
echo "== Creating demo file with wrong DAC and SELinux context =="
echo "<h1>Hello CU</h1>" > "$DEMO_FILE"
chown "$USER_NAME":"$USER_NAME" "$DEMO_FILE"
chmod 600 "$DEMO_FILE"
mv "$DEMO_FILE" "$TARGET_FILE"

# httpd servisis konfiguracia konkretul portze requestebis misagebad

sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf

cat <<EOF > "$VHOST_CONF"
Listen $CUSTOM_PORT

<VirtualHost *:$CUSTOM_PORT>
    DocumentRoot "/var/www/html"
    ErrorLog logs/broken_error.log
    CustomLog logs/broken_access.log combined
</VirtualHost>
EOF

#dakonfigurirebul portze selinux uflebebis moxsna
if semanage port -l | grep -q "^http_port_t.*$CUSTOM_PORT"; then
  semanage port -d -t http_port_t -p tcp $CUSTOM_PORT
else
  echo "SELinux has no mapping for $CUSTOM_PORT"
fi

echo
echo "== Current SELinux httpd port mappings =="
semanage port -l | grep ^http_port_t

echo
echo "== File's DAC and SELinux context:"
ls -lZ "$TARGET_FILE"
echo ""

echo
echo "== Restarting Apache =="
systemctl restart httpd

echo "==  Apache status summary:"
systemctl is-active httpd && echo "[✓] httpd is active" || echo "[X] httpd failed to start"
echo ""

echo "== Testing curl to http://localhost:$CUSTOM_PORT"
echo

curl http://localhost:$CUSTOM_PORT

