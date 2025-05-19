cp ~/Developer/fcomrqz/dotfiles/tailscale/tailscale.plist /Library/LaunchDaemons/com.tailscale.tailscaled.plist
launchctl load /Library/LaunchDaemons/com.tailscale.tailscaled.plist
chmod 644 /Library/LaunchDaemons/com.tailscale.tailscaled.plist
chown root:wheel /Library/LaunchDaemons/com.tailscale.tailscaled.plist

fdesetup list -extended
fdesetup status -extended
fdesetup authrestart -extended
