# kanata on macOS — driver setup notes

## Why this exists

kanata 1.12.0 speaks the **Karabiner-DriverKit-VirtualHIDDevice v6.2.0** IPC
(local datagram socket `…/tmp/rootonly/vhidd_server`), so it only works with
driver 6.2.0. Karabiner-Elements 16.x ships driver **v8.5.0**, which switched to a
Unix-stream protocol, causing:

```
connect_failed asio.system:2
[INFO] Waiting for DriverKit virtual keyboard... (x/10.0s)
```

Karabiner-Elements also seizes the keyboard, which produces:

```
IOHIDDeviceOpen error: (iokit/common) exclusive access and device already open
Apple Internal Keyboard / Trackpad
```

=> Karabiner-Elements 16 and kanata cannot be installed/run at the same time.

## What was installed

| Item | Path |
|---|---|
| Karabiner driver 6.2.0 (pkg) | `/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice` |
| VHID daemon LaunchDaemon | `/Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist` |
| kanata LaunchDaemon | `/Library/LaunchDaemons/dev.kanata.kanata.plist` |
| kanata | `/opt/homebrew/bin/kanata` (Homebrew) |
| config | `~/.config/kanata/kanata.kbd` → `dotfiles/kanata/.config/kanata/kanata.kbd` |

TCC permissions required for `/opt/homebrew/bin/kanata`:
System Settings → Privacy & Security → **Input Monitoring** + **Accessibility**.

Karabiner-Elements was uninstalled. The old `brew services` plist is kept as
`/Library/LaunchDaemons/sh.brew.kanata.plist.disabled` — do **not** re-enable it,
otherwise two kanata instances fight over the keyboard.

## Daily commands

```sh
# status
sudo launchctl print system/dev.kanata.kanata | head -5
pgrep -fl kanata

# after editing kanata.kbd
sudo launchctl kickstart -k system/dev.kanata.kanata

# logs
tail -f /var/log/kanata.log

# emergency exit (defsrc keys, before remapping)
# hold lctl + spc + esc
```

## Reinstall from scratch

```sh
# 1. quit/uninstall any Karabiner-Elements, then:
sudo bash kanata/setup/setup-macos-vhid.sh \
  /path/to/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg

# 2. reboot, approve the system extension if asked

# 3. kanata daemon
sudo cp kanata/setup/dev.kanata.kanata.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/dev.kanata.kanata.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.kanata.plist

# 4. grant Input Monitoring + Accessibility to /opt/homebrew/bin/kanata
```

## Caveats

- **Do not reinstall Karabiner-Elements** — it brings back driver v8.5.0 and
  breaks kanata until the driver is downgraded again.
- **Homebrew upgrade of kanata** may invalidate the TCC grants (macOS pins the
  binary path). If kanata starts but keys stop being remapped, remove the stale
  entries in Input Monitoring/Accessibility and re-add the binary.
- Karabiner-Elements' per-app rules (terminals: `ctrl+;` → `ctrl+b`) cannot be
  reproduced by kanata; configure those in the terminal itself.
