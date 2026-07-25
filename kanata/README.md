# Kanata on macOS

Kanata and the Karabiner VirtualHIDDevice daemon run as root-owned system
LaunchDaemons. Runtime files live under
`/Library/Application Support/com.fcomrqz.kanata`; launchd does not execute files
from this repository or the user-owned Homebrew prefix.

## Configuration-only update

```bash
kanata --check -c ~/Developer/fcomrqz/dotfiles/kanata/kanata.kbd
sudo /bin/bash ~/Developer/fcomrqz/dotfiles/kanata/manage-daemons.sh \
  install \
  "$(command -v kanata)" \
  ~/Developer/fcomrqz/dotfiles/kanata/kanata.kbd \
  "$(id -u)" \
  "$HOME"
```

The installer refuses this path if the Homebrew and protected Kanata binaries
differ. Binary updates use the staged workflow below so macOS privacy permissions
can be renewed before activation.

## Kanata binary update

```bash
brew update
brew upgrade kanata
kanata --version
kanata --check -c ~/Developer/fcomrqz/dotfiles/kanata/kanata.kbd

sudo /bin/bash ~/Developer/fcomrqz/dotfiles/kanata/manage-daemons.sh \
  stage \
  "$(command -v kanata)" \
  ~/Developer/fcomrqz/dotfiles/kanata/kanata.kbd
```

Staging snapshots the active protected deployment, disables both system jobs,
and places the candidate at its final protected path without activating it:

```text
/Library/Application Support/com.fcomrqz.kanata/bin/kanata
```

Remove and re-add that path under both **Privacy & Security → Input Monitoring**
and **Privacy & Security → Accessibility** if macOS marks the upgraded binary as
unauthorized. Then activate it:

```bash
sudo /bin/bash ~/Developer/fcomrqz/dotfiles/kanata/manage-daemons.sh \
  activate-staged "$(id -u)" "$HOME"
```

Activation restarts both jobs and health-checks them. If it fails, the previous
protected deployment is restored automatically.

To discard a staged update before activation:

```bash
sudo /bin/bash ~/Developer/fcomrqz/dotfiles/kanata/manage-daemons.sh abort-staged
```

## Protected rollback

```bash
sudo /bin/bash ~/Developer/fcomrqz/dotfiles/kanata/manage-daemons.sh rollback
```

Rollback switches to the previous root-owned deployment. The deployment it
replaces becomes the next rollback target.

## Keyboard availability

The root-owned launcher waits quietly while `HHKB-Classic` is absent. During
the first 30 seconds after startup it checks once per second, which covers the
short delay while macOS initializes USB devices. It then falls back to one
check every ten minutes to avoid continuous process and device-enumeration
overhead.

If a Kanata process that ran for at least 30 seconds exits, the launcher opens
a new 30-second fast-retry window. A process that fails immediately does not
keep generating processes and logs once per second.
