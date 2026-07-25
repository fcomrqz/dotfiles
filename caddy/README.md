# Caddy

Caddy is installed by Homebrew and runs as a user LaunchAgent. It does not run
as root.

macOS permits an unprivileged process to bind a low port on every interface,
but not directly on a specific interface. The small `caddy-launcher` helper
receives IPv4 and IPv6 loopback port 443 sockets from launchd and passes those
file descriptors to Caddy. This keeps the development server unreachable from
the LAN without granting Caddy elevated privileges.

The LaunchAgent uses Homebrew's stable path:

```text
/opt/homebrew/opt/caddy/bin/caddy
```

## Update

```sh
brew update
brew upgrade caddy
brew services restart caddy --file="$HOME/Developer/fcomrqz/dotfiles/caddy/homebrew.mxcl.caddy.plist"
```

Homebrew verifies the downloaded formula bottle. Restarting switches the
running process to the version selected by Homebrew's `opt/caddy` symlink.

## Verify

```sh
brew services info caddy
caddy version
lsof -nP -a -c caddy -iTCP -sTCP:LISTEN
```

The expected public listeners are `127.0.0.1:443` and `[::1]:443`. The admin
API listens on `127.0.0.1:2019`.
