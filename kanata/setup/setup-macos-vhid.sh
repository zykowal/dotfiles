#!/bin/bash
#
# Switch macOS from Karabiner-Elements 16.x (VirtualHIDDevice driver v8)
# to Karabiner-DriverKit-VirtualHIDDevice v6.2.0, which is the only driver
# version kanata 1.12.0 speaks (it connects to the v6 IPC socket
# /Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server).
#
# Symptoms this fixes:
#   connect_failed asio.system:2
#   IOHIDDeviceOpen error: (iokit/common) exclusive access and device already open
#
# Usage:
#   sudo bash setup-macos-vhid.sh /path/to/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg
#
# Run it once, then reboot (the system extension has to be replaced).

set -u

PKG="${1:-}"
if [ -z "$PKG" ] || [ ! -f "$PKG" ]; then
    echo "usage: sudo $0 /path/to/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DAEMON_PLIST_SRC="$SCRIPT_DIR/karabiner-vhid-daemon.plist"
DAEMON_PLIST_DST=/Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist

step() { echo; echo "==> $*"; }

step "1/6 quit Karabiner-Elements"
osascript -e 'tell application "Karabiner-Elements" to quit' >/dev/null 2>&1 || true
sleep 1

step "2/6 uninstall Karabiner-Elements (official uninstaller)"
if [ -f "/Library/Application Support/org.pqrs/Karabiner-Elements/uninstall.sh" ]; then
    bash "/Library/Application Support/org.pqrs/Karabiner-Elements/uninstall.sh" || true
else
    echo "    (Karabiner-Elements already removed)"
fi

step "3/6 kill leftover VirtualHID daemons and clear runtime state"
pkill -f Karabiner-VirtualHIDDevice-Daemon 2>/dev/null || true
rm -rf "/Library/Application Support/org.pqrs"

step "4/6 install Karabiner-DriverKit-VirtualHIDDevice 6.2.0"
/usr/sbin/installer -pkg "$PKG" -target / || { echo "installer failed"; exit 1; }

step "5/6 activate driver + install VHID daemon LaunchDaemon"
/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager forceActivate || true

if [ -f "$DAEMON_PLIST_SRC" ]; then
    cp "$DAEMON_PLIST_SRC" "$DAEMON_PLIST_DST"
else
    echo "missing $DAEMON_PLIST_SRC" >&2
fi
chown root:wheel "$DAEMON_PLIST_DST"
chmod 644 "$DAEMON_PLIST_DST"
launchctl bootout system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon 2>/dev/null || true
launchctl bootstrap system "$DAEMON_PLIST_DST" || true

step "6/6 verify"
echo "-- daemon bundle version (expect 6.2.0) --"
defaults read "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/Info.plist" CFBundleShortVersionString 2>&1
echo "-- system extensions --"
systemextensionsctl list 2>&1 | grep -i pqrs || true
echo "-- launchd daemon --"
launchctl list 2>/dev/null | grep -i pqrs || true
echo "-- runtime dir --"
ls -la "/Library/Application Support/org.pqrs/tmp/rootonly" 2>&1 || true

echo
echo "Done. Reboot now, then check:"
echo '  sudo ls -la "/Library/Application Support/org.pqrs/tmp/rootonly"   # expect vhidd_server'
echo "  sudo kanata --no-wait -c ~/.config/kanata/kanata.kbd"
