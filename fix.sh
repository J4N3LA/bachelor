#!/bin/bash

# Only run as root
if [ "$EUID" -ne 0 ]; then
  echo "run this script as root."
  exit 1
fi

CUSTOM_PORT=8088
TARGET_FILE=/var/www/html/index.html
systemctl enable --now httpd --quiet

##Fix Selinux port label for port
echo "✅==  Adding SELinux port $CUSTOM_PORT to http_port_t  =="
if ! semanage port -l | grep -q "^http_port_t.*$CUSTOM_PORT"; then
  semanage port -a -t http_port_t -p tcp $CUSTOM_PORT
else
  echo "SELinux already allows httpd to bind to $CUSTOM_PORT"
fi
echo "--> Selinux port configuration after changes"
semanage port -l | grep "^http_port_t.*"


#Testing Selinux port configuration reusult

echo "❓== Testing httpd service =="
systemctl restart httpd
echo "--> httpd status: $(systemctl is-active httpd )"
echo  
echo "--> Response from webserver "
curl localhost:$CUSTOM_PORT
echo

## Fixsing file index.html DAC permissions
echo "✅== Correcting file ownership, permissions, and context =="
chown apache:apache "$TARGET_FILE"
chmod 644 "$TARGET_FILE"
echo "--> File after fix:"
ls -lZ "$TARGET_FILE"

# Testing file DAC fix results
echo "❓== Testing httpd service =="
systemctl restart httpd
echo "--> httpd status: $(systemctl is-active httpd )"
echo  
echo "--> Response from webserver "
curl localhost:$CUSTOM_PORT
echo


##Fixing file's selinux context type

echo "✅ == Correcting file's context ==" ;
restorecon "$TARGET_FILE"

echo "--> File's context after fix:"
ls -lZ "$TARGET_FILE"
echo ""
# Testing file Context fix results
echo "❓== Testing httpd service =="
systemctl restart httpd
echo "--> httpd status: $(systemctl is-active httpd )"
echo ""

echo "-->  Response from webserver: http://localhost:$CUSTOM_PORT"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:$CUSTOM_PORT
curl localhost:$CUSTOM_PORT
echo

