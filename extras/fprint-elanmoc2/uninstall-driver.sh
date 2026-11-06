#!/bin/sh
# Back to Ubuntu's own libfprint.
set -e
rm -f /usr/local/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0 /usr/local/lib/x86_64-linux-gnu/libfprint-2.so.2
rm -f /etc/udev/rules.d/70-libfprint-2.rules
ldconfig
udevadm control --reload
systemctl restart fprintd
echo "removed: Ubuntu's libfprint is in use again"
