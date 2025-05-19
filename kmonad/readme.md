# Instructions

https://github.com/kmonad/kmonad/blob/master/doc/installation.md

## Edit sudoers

```sh
sudo visudo /etc/sudoers
```

Add

`fran ALL=(ALL) NOPASSWD: /Users/fran/.local/bin/kmonad, /Library/Application\ Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon`

Give permissions to Karabiner in:
System Settings → General → Login Items & Extensions → Driver Extensions → Karabiner

Give permisions to Kmonad in:
System Settings → Privacy & Security → Input Monitoring → Add Kmonad showing hidden files in Finder (cmd + shift + .)
