#!/bin/sh
# Installs the elanmoc2 build of libfprint next to Ubuntu's: nothing under /usr/lib is touched.
# /usr/local/lib/x86_64-linux-gnu is searched before /usr/lib/x86_64-linux-gnu, so fprintd picks this one up.
# Undo: sh uninstall-driver.sh
set -e
B="$(dirname "$0")/libfprint/build/libfprint"
install -d /usr/local/lib/x86_64-linux-gnu
install -m 755 "$B/libfprint-2.so.2.0.0" /usr/local/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0
ln -sf libfprint-2.so.2.0.0 /usr/local/lib/x86_64-linux-gnu/libfprint-2.so.2
ldconfig
# same file name as the package's rules: /etc wins, the package file stays as it is
install -m 644 "$B/70-libfprint-2.rules" /etc/udev/rules.d/70-libfprint-2.rules
udevadm control --reload
udevadm trigger --subsystem-match=usb
systemctl restart fprintd
echo "installed: now run  fprintd-list \$USER"
