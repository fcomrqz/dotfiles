# Hardened remote access

Remote administration terminates on macOS. Ubuntu remains outside the tailnet:

```text
trusted remote device -> Tailscale SSH -> macOS -> orb/ssh orb -> Ubuntu
```

The ChatGPT mobile app uses a separate secure relay to the ChatGPT desktop app
on macOS. The desktop app then starts the remote Codex app server in Ubuntu
through `ssh orb`. Disabling Apple Remote Login does not disable Codex Remote.

## Install the daemon

The macOS installer installs the open-source Homebrew `tailscale` and
`tailscaled` binaries, then installs `tailscaled` as a system LaunchDaemon:

```sh
bash install.sh
```

The daemon manager renders the Homebrew binary path into the plist, validates
it, and avoids restarting an already-current service. When replacing an older
plist, it preserves the existing Tailscale state and restores the previous
service if the new one cannot start.

Inspect the service without changing it:

```sh
tailscale/manage-daemon.sh status
```

## Configure the tailnet

Do these steps from the Tailscale admin console before disabling any existing
remote access:

1. Enable multi-factor authentication or passkeys at the identity provider.
2. Enable device approval and approve only the Mac and trusted remote devices.
3. Keep node-key expiration enabled.
4. Confirm the Mac's current address with `tailscale ip -4`. If it differs from
   the `privileged-mac` host alias in `policy.hujson.example`, update the alias.
5. Merge the sections from `policy.hujson.example` into the existing tailnet
   policy without deleting unrelated policy.

The checked-in template is scoped to the current `fcomrqz@github` Tailscale
identity and the `fran` macOS account. Update those values if either identity
changes.

The network grant permits the approved identity only TCP 22 to the named Mac.
The SSH rule uses `autogroup:self`, because Tailscale SSH accepts a user, tag, or
autogroup—but not a host alias—as its destination. Together, those two rules
still limit the usable SSH destination to the Mac. Every SSH connection uses
check mode; omitting `checkPeriod` uses Tailscale's 12-hour reauthentication
window on plans that do not support a custom period. Only the `fran` account is
listed, so `root` and other local accounts are denied. The host alias preserves
the Mac's user identity and normal key expiry; do not tag this personal device.

## Enable Tailscale SSH

The Mac must already have the open-source LaunchDaemon running. Enable its
Tailscale SSH server explicitly:

```sh
sudo tailscale/manage-daemon.sh enable-ssh
```

On a new node, this prints an authentication URL. Complete it, approve the node,
update the policy's host IP if necessary, and confirm that the policy is active.

Tailscale SSH is independent of macOS Remote Login. Do not enable SSH inside the
OrbStack Ubuntu machine and do not add Ubuntu to the tailnet.

## Cut over without lockout

Keep Apple Remote Login available until all of these checks succeed from a
different network:

1. Connect the trusted remote device to the tailnet.
2. Run `ssh MACOS_USERNAME@MAC_MAGICDNS_NAME`.
3. Confirm the identity-provider check appears when the 12-hour authorization
   window has expired.
4. From the remote Mac shell, run `orb -m ubuntu` and verify the shell is in
   Ubuntu.
5. From the ChatGPT app on iPhone, start a Codex Remote task for the Ubuntu
   project and verify its commands execute in Ubuntu.

The Mac must remain awake, online, signed in to ChatGPT, and running the ChatGPT
desktop app for Codex Remote. Keep **Allow other devices to connect** enabled in
ChatGPT's connection settings.

Only after those checks pass, disable Apple Remote Login locally:

```sh
sudo systemsetup -setremotelogin off
```

Also remove any router port forwarding for TCP 22. From another device on the
LAN, verify that TCP 22 on the Mac's LAN address is closed. Finally, repeat both
the Tailscale SSH and iPhone Codex Remote tests.

## FileVault and restarts

The system daemon can run before a normal macOS login, but it cannot run before
FileVault unlocks the startup volume. After an unexpected shutdown or cold
boot, someone must unlock the Mac locally before remote access returns.

For a planned restart, `fdesetup authrestart` can authorize one restart without
another FileVault login. Treat that as an explicit operational action; it is
not part of the installer.

## Rollback

Use a local Mac session or another confirmed access path before disabling
Tailscale SSH:

```sh
sudo systemsetup -setremotelogin on
sudo tailscale/manage-daemon.sh disable-ssh
```

Restore the previous tailnet policy if necessary. To remove only the system
daemon while preserving authentication state and logs:

```sh
sudo tailscale/manage-daemon.sh uninstall
```
