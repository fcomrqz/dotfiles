# Dotfiles

macOS host configuration plus an isolated Ubuntu development environment
managed with OrbStack.

Development agents, command-line build tools, local HTTPS, and public tunnels
run in Linux. Xcode, Android Studio/emulators, and desktop applications stay on
macOS.

## macOS setup

Install the Xcode Command Line Tools, clone this repository, and run:

```sh
bash install.sh
```

The macOS installer manages:

- Fish, GitHub CLI, Git Delta, `mas`, Kanata, and Tailscale.
- Zed, AeroSpace, Chrome, OrbStack, KeyCastr, Figma, Android Studio,
  Temurin 17, ChatGPT, SF Symbols, and Parallels.
- Xcode, Numbers, WhatsApp, Pure Paste, Pandan, Base, and Things.
- Fish, Git, Zed, AeroSpace, Kanata, Keytics, Terminal themes, and macOS
  defaults.

Git comes from the Apple developer tools. Swift formatting uses:

```sh
xcrun swift-format
```

The installer is repeatable and resolves this checkout from its own location;
it does not require the repository to live at a particular home-directory
path.

Interactive installs show structured progress and keep command output hidden
unless a step fails. Set `INSTALL_VERBOSE=1` to stream the underlying command
output while troubleshooting:

```sh
INSTALL_VERBOSE=1 bash install.sh
```

## GitHub App authentication

Ubuntu uses a GitHub App installation instead of a personal GitHub login. The
App is installed for all repositories, while its permissions remain limited to
the operations development agents require:

- Metadata: read-only.
- Contents: read and write.
- Pull requests: read and write.

Keep branch protections and required reviews enabled. Add other App
permissions only when a concrete workflow needs them.

Copy the **Client ID** from the App's General settings, generate a private key,
and find the installation ID in the installation URL. Use the Client ID—not
the numeric App ID—as the JWT issuer. After running `bash install.sh`,
configure the helper on macOS:

```sh
orbstack/machine github configure \
  CLIENT_ID \
  INSTALLATION_ID \
  ~/Downloads/GITHUB_APP.private-key.pem
```

Configuration imports the RSA private key into the macOS login Keychain. The
downloaded PEM is deliberately not deleted; remove or archive it securely after
the helper is confirmed working.

The native Swift LaunchAgent runs as the logged-in macOS user. It creates a
one-hour installation token, refreshes it before expiration, and sends it to a
fixed command in Ubuntu using OrbStack's `ORBENV` forwarding. No Mac directory,
network service, personal token, or App private key is exposed to Linux.

Useful controls:

```sh
orbstack/machine github status
orbstack/machine github refresh
orbstack/machine github stop
orbstack/machine github start
orbstack/machine github reset
```

`stop` unloads the LaunchAgent and removes the current token from Ubuntu.
`reset` additionally deletes the Keychain private key and non-secret
configuration.

Inside Ubuntu, the current token is held at:

```text
/run/fcomrqz-github-app/fcomrqz/token.json
```

The file is user-owned, mode `0600`, replaced atomically, and lost on machine
restart. A root-installed `gh` wrapper sets `GH_TOKEN` only for the real GitHub
CLI process. Git uses a root-installed credential helper with
`x-access-token` over HTTPS. Do not run `gh auth login` inside Ubuntu.

The App private key never leaves Keychain, but Codex can extract the active
installation token because it is allowed to use Git and `gh`. Since the helper
runs indefinitely and the App covers every repository, compromised agent code
can continue requesting one-hour tokens until the helper is stopped, the App
is uninstalled, or the private key is revoked.

## Isolated development machine

Create the default Ubuntu 26.04 LTS machine:

```sh
orbstack/machine create
```

The machine is named `ubuntu` by default and its development user is always
`fcomrqz`, independently of the macOS account name. It is created with:

- OrbStack isolation and network isolation.
- No macOS filesystem mount.
- No SSH-agent forwarding.
- Machine ports unavailable to the LAN.
- No desktop environment.
- No passwordless or guest-accessible sudo after provisioning.

Provisioning clones this public repository directly from GitHub. Linux
checkouts follow this layout:

```text
/home/fcomrqz/
├── dotfiles/       # Primary dotfiles checkout
├── bookip/         # Primary application checkout
└── worktrees/      # Task worktrees grouped by repository
    └── bookip/
```

Provisioning updates `/home/fcomrqz/dotfiles` with a fast-forward-only merge.
It refuses to overwrite a different repository or a checkout with local
changes. Privileged installation runs from a separate root-owned clone at
`/var/lib/fcomrqz-dotfiles/source`; agents cannot turn edits in the user
checkout into root execution during a later provision.

Linux receives Fish, Git, GitHub CLI, Git Delta, Node.js, npm, Bun, Micro,
Fly CLI, Stripe CLI, SQLite, `jq`, Ripgrep, ShellCheck, `scc`, FFmpeg, Caddy,
`dnsmasq`, `cloudflared`, Codex, and the Ubuntu libraries required by
Playwright's Chromium, Firefox, and WebKit builds. Playwright and its
version-matched browser binaries remain project-managed and run without root.

Administration remains available from macOS:

```sh
orb -m ubuntu -u root
```

The required GitHub App helper must be configured before machine creation.
Other host credentials are deliberately not copied.

## Secrets

Codex service authentication belongs to the Ubuntu machine and is separate
from GitHub App authentication. Authenticate without
putting an API key in Fish configuration or shell history:

```sh
orb -m ubuntu
codex login --device-auth
codex login status
```

Codex uses the operating-system credential store when one is available and
otherwise stores its login in `~/.codex/auth.json`. The Linux installer keeps
`~/.codex` private. A root-owned `/etc/codex/requirements.toml` restricts Codex
to read-only or workspace-write sandbox modes and denies sandboxed commands
access to that file. Root-owned managed configuration defaults to workspace
writes with network access, limits the environment inherited by agent-run
subprocesses, and explicitly removes common credential variables.

Project secrets live outside every checkout:

```text
~/.config/fcomrqz/secrets/PROJECT.env
```

Create a file from a terminal inside Ubuntu:

```sh
umask 077
touch ~/.config/fcomrqz/secrets/bookip.env
chmod 600 ~/.config/fcomrqz/secrets/bookip.env
$EDITOR ~/.config/fcomrqz/secrets/bookip.env
```

Its contents use shell-compatible assignments:

```sh
DATABASE_URL='postgresql://...'
STRIPE_SECRET_KEY='sk_test_...'
```

Keep only non-secret examples such as `.env.example` in Git. Do not put secret
values in this repository, Fish universal variables, `cloud-init.yml`, or
Codex configuration.

Run Codex and the secret-bearing application in separate Ubuntu terminals:

```text
Terminal 1:  codex
Terminal 2:  with-secrets bookip bun run dev
```

`with-secrets` verifies that the directory and file belong to the current user
and are inaccessible to group and other users. It then loads the selected file
and replaces itself with the application. Root-owned Codex requirements deny
the secrets directory and cannot be weakened by user, project, or command-line
configuration. Local `.env` files remain readable so Codex can work with
non-secret development configuration and fixtures; secrets must live in the
external secrets directory. Root-owned managed defaults prevent projects from
changing the subprocess environment policy at startup. The installer copies
the launcher and Codex user configuration rather than linking them into the
agent-editable checkout; changes take effect only after explicit provisioning.

This prevents direct access from sandboxed agent commands. It cannot make a
secret safe from application code that receives it, so agent-tested
integrations should use disposable, least-privilege development credentials,
never production credentials. Do not approve a sandbox escalation that asks
to run `with-secrets` or read the secrets directory.

The installer ensures Codex supports the managed sandbox configuration. See the
official [authentication](https://learn.chatgpt.com/docs/auth#credential-storage)
and
[managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration#enforce-deny-read-requirements)
documentation.

Fetch the public dotfiles checkout and repeat provisioning:

```sh
orbstack/machine provision
```

Run health checks:

```sh
orbstack/machine doctor
```

## Wildcard `.test` domains

There is one wildcard DNS server: `dnsmasq` inside the Linux machine.

1. `dnsmasq` resolves every `*.test` name to the machine's isolated IPv4
   address.
2. Linux sends DNS through that `dnsmasq`; non-`.test` queries are forwarded
   to OrbStack's macOS-aware DNS resolver.
3. macOS `/etc/resolver/test` sends only host `.test` lookups to the same
   server.
4. Caddy listens on Linux port 443 and maps each hostname to its application's
   local port through the Caddy admin API.

For example, several instances can coexist:

```text
feature-one.test -> 127.0.0.1:3001
feature-two.test -> 127.0.0.1:3002
review.test      -> 127.0.0.1:4173
```

Caddy owns a local development CA. The machine script trusts only its root
certificate inside Linux and on macOS; its private key stays inside Linux.

If OrbStack changes the machine IP or the CA is recreated, refresh macOS:

```sh
orbstack/machine sync-host
```

The `.test` namespace is available only while the machine is running.
The first successful host sync removes the superseded Homebrew Caddy,
`dnsmasq`, and `cloudflared` installations; the macOS installer leaves them
alone until that handoff succeeds.

## Public Quick Tunnels

Expose one application instance directly by port:

```sh
orbstack/machine tunnel 3001
```

This starts a foreground Cloudflare Quick Tunnel and prints its temporary
public URL. It does not store Cloudflare credentials or expose Caddy's admin
API or DNS server. Stop it with Ctrl-C.

## Security boundary

OrbStack isolation protects the Mac filesystem, host network, and SSH agent,
but isolated machines still share OrbStack's Linux kernel. This is appropriate
for routine agent work and untrusted build dependencies, not for malware
analysis or code expected to attempt a kernel escape. See the
[OrbStack isolation model](https://docs.orbstack.dev/machines/isolated).

## Fish filter

The interactive history, project, and file selectors use a Fish
implementation of the Gum 0.14.5 single-select UI. It preserves the prompt,
indicator, colors, fuzzy scoring, highlighted matches, wraparound navigation,
scrolling, and stdout/stderr behavior used by these dotfiles without installing
Gum. Non-empty searches retain the best 256 matches so large history lists
remain responsive while the query is refined.

`open_project` scans `$HOME/Developer` on macOS and `$HOME` on Linux for
primary clones, then includes their registered Git worktrees wherever they
live. Entries use `repo [status] branch`; worktree identifiers are
omitted, and changed checkouts retain the yellow `*` status marker. Current
working-tree edits determine the recent-first order. A detached HEAD uses
`@<short-hash>` in place of the branch and does not repeat the commit.

Upstream attribution is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
