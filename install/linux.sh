#!/bin/bash

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOTFILES_ROOT
# shellcheck source=install/shared.sh
source "$DOTFILES_ROOT/install/shared.sh"

if [[ "$(uname -s)" != "Linux" ]]; then
  log_error "The Linux installer can only run on Linux."
  exit 1
fi

linux_arch() {
  case "$(uname -m)" in
    aarch64 | arm64) printf 'arm64\n' ;;
    x86_64 | amd64) printf 'amd64\n' ;;
    *)
      log_error "Unsupported Linux architecture: $(uname -m)"
      return 1
      ;;
  esac
}

github_asset_metadata() {
  local repository="$1"
  local pattern="$2"
  curl -fsSL "https://api.github.com/repos/$repository/releases/latest" \
    | jq -r --arg pattern "$pattern" \
      'first(
        .assets[] | select(.name | test($pattern)) |
        [.browser_download_url, (.digest // "")] | @tsv
      )'
}

download_github_asset() {
  local repository="$1"
  local pattern="$2"
  local destination="$3"
  local metadata url digest

  metadata="$(github_asset_metadata "$repository" "$pattern")"
  IFS=$'\t' read -r url digest <<< "$metadata"
  [[ -n "$url" ]] || {
    log_error "Could not find a release asset for $repository matching $pattern"
    return 1
  }
  download "$url" "$destination"
  chmod 0644 "$destination"
  if [[ "$digest" == sha256:* ]]; then
    printf '%s  %s\n' "${digest#sha256:}" "$destination" | sha256sum --check --status
  fi
}

install_github_deb() {
  local repository="$1"
  local pattern="$2"
  local package="$3"
  local temporary

  if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -Fq 'install ok installed'; then
    return 0
  fi
  temporary="$(mktemp --suffix=.deb)"
  download_github_asset "$repository" "$pattern" "$temporary"
  apt-get install -y "$temporary"
  rm -f "$temporary"
}

install_github_archive_binary() {
  local repository="$1"
  local pattern="$2"
  local binary_name="$3"
  local destination="/usr/local/bin/$binary_name"
  local temporary directory source

  if [[ -x "$destination" ]]; then
    return 0
  fi
  temporary="$(mktemp --suffix=.tar.gz)"
  directory="$(mktemp -d)"
  download_github_asset "$repository" "$pattern" "$temporary"
  tar -xzf "$temporary" -C "$directory"
  source="$(find "$directory" -type f -name "$binary_name" -perm -u+x -print -quit)"
  [[ -n "$source" ]] \
    || source="$(find "$directory" -type f -name "$binary_name" -print -quit)"
  [[ -n "$source" ]] || {
    log_error "The $repository archive did not contain $binary_name"
    return 1
  }
  install -o root -g root -m 0755 "$source" "$destination"
  rm -f "$temporary"
  rm -rf "$directory"
}

install_github_deb_step() {
  local repository="$1"
  local pattern="$2"
  local package="$3"
  local title="$4"

  if dpkg-query -W -f='${Status}' "$package" 2>/dev/null \
    | grep -Fq 'install ok installed'; then
    log_skip "$title is already installed"
  else
    run_step "Installing $title" \
      install_github_deb "$repository" "$pattern" "$package"
  fi
}

install_github_archive_binary_step() {
  local repository="$1"
  local pattern="$2"
  local binary_name="$3"
  local title="$4"

  if [[ -x "/usr/local/bin/$binary_name" ]]; then
    log_skip "$title is already installed"
  else
    run_step "Installing $title" \
      install_github_archive_binary \
      "$repository" "$pattern" "$binary_name"
  fi
}

codex_supports_managed_sandbox() {
  local codex_command version major minor

  if command_exists codex; then
    codex_command="$(command -v codex)"
  elif [[ -x "$HOME/.local/bin/codex" ]]; then
    codex_command="$HOME/.local/bin/codex"
  else
    return 1
  fi
  version="$("$codex_command" --version 2>/dev/null | awk 'NR == 1 {print $2}')"
  [[ "$version" =~ ^([0-9]+)\.([0-9]+)\. ]] || return 1
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  (( major > 0 || minor >= 138 ))
}

install_bun() {
  if [[ -x "$HOME/.bun/bin/bun" ]]; then
    log_skip "Bun JavaScript runtime is already installed"
    return 0
  fi

  # Put the destination on PATH before running Bun's official installer. Once
  # the binary exists, the installer detects it and does not append duplicate
  # configuration to our symlinked Fish config.
  run_step "Installing Bun JavaScript runtime" \
    env \
    BUN_INSTALL="$HOME/.bun" \
    PATH="$HOME/.bun/bin:$PATH" \
    /bin/bash -c \
    'set -euo pipefail
    curl -fsSL https://bun.com/install | /bin/bash'

  "$HOME/.bun/bin/bun" --version >/dev/null
}

install_playwright_dependencies() {
  # Native dependencies declared by Playwright for Ubuntu 26.04. Keep browser
  # downloads user- and project-managed so their revisions continue to match
  # the Playwright package version. Never execute project-provided npx/bunx
  # code as root to install these packages.
  apt-get install -y --no-install-recommends \
    fonts-freefont-ttf \
    fonts-ipafont-gothic \
    fonts-liberation \
    fonts-noto-color-emoji \
    fonts-tlwg-loma-otf \
    fonts-unifont \
    fonts-wqy-zenhei \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatk1.0-0t64 \
    libatspi2.0-0t64 \
    libatomic1 \
    libavcodec62 \
    libavif16 \
    libcairo-gobject2 \
    libcairo2 \
    libcups2t64 \
    libdbus-1-3 \
    libdrm2 \
    libenchant-2-2 \
    libepoxy0 \
    libevent-2.1-7t64 \
    libflite1 \
    libfontconfig1 \
    libfreetype6 \
    libgbm1 \
    libgdk-pixbuf-2.0-0 \
    libgles2 \
    libglib2.0-0t64 \
    libgraphene-1.0-0 \
    libgstreamer-gl1.0-0 \
    libgstreamer-plugins-bad1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer1.0-0 \
    libgtk-3-0t64 \
    libgtk-4-1 \
    libharfbuzz-icu0 \
    libharfbuzz0b \
    libhyphen0 \
    libicu78 \
    libjpeg-turbo8 \
    liblcms2-2 \
    libmanette-0.2-0 \
    libnspr4 \
    libnss3 \
    libopus0 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpng16-16t64 \
    libsecret-1-0 \
    libvpx12 \
    libwayland-client0 \
    libwayland-egl1 \
    libwayland-server0 \
    libwebp7 \
    libwebpdemux2 \
    libwoff1 \
    libx11-6 \
    libx11-xcb1 \
    libx264-165 \
    libxcb-shm0 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxkbcommon0 \
    libxml2-16 \
    libxrandr2 \
    libxrender1 \
    libxslt1.1 \
    xfonts-cyrillic \
    xfonts-scalable \
    xvfb
}

install_caddy_repository() {
  local keyring="/usr/share/keyrings/caddy-stable-archive-keyring.gpg"
  local repository="/etc/apt/sources.list.d/caddy-stable.list"

  if [[ ! -f "$keyring" || ! -f "$repository" ]]; then
    install -d -m 0755 "$(dirname "$keyring")"
    curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
      | gpg --dearmor --yes -o "$keyring"
    curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt \
      > "$repository"
  fi
}

prepare_fish_configuration() {
  local config="$HOME/.config/fish/config.fish"
  local default_config

  default_config="$(cat <<'EOF'
if status is-interactive
    # Commands to run in interactive sessions can go here
end
EOF
)"

  # Fish may create this untouched starter file and empty directory on first
  # launch. Remove only those generated defaults; safe_link still refuses to
  # replace any user-authored file or non-empty directory.
  if [[ -f "$config" && ! -L "$config" ]] \
    && [[ "$(cat "$config")" == "$default_config" ]]; then
    rm "$config"
  fi
  if [[ -d "$HOME/.config/fish/functions" ]] \
    && [[ ! -L "$HOME/.config/fish/functions" ]] \
    && [[ -z "$(find "$HOME/.config/fish/functions" -mindepth 1 -print -quit)" ]]; then
    rmdir "$HOME/.config/fish/functions"
  fi
}

configure_dns() {
  local guest_ip="$1"
  local upstream_dns
  step_progress "discovering OrbStack's upstream resolver"
  [[ "$guest_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    log_error "Invalid guest IPv4 address: $guest_ip"
    return 1
  }

  upstream_dns="$(
    awk '$1 == "nameserver" && $2 != "127.0.0.1" {print $2; exit}' \
      /etc/resolv.conf
  )"
  if [[ -z "$upstream_dns" && -f /etc/dnsmasq.d/test.conf ]]; then
    upstream_dns="$(
      awk -F= '$1 == "server" {print $2; exit}' \
        /etc/dnsmasq.d/test.conf
    )"
  fi
  [[ "$upstream_dns" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    log_error "Could not discover OrbStack's upstream DNS resolver."
    return 1
  }

  step_progress "writing the dnsmasq configuration"
  cat > /etc/dnsmasq.d/test.conf <<EOF
# Managed by fcomrqz/dotfiles.
local=/test/
address=/.test/$guest_ip
server=$upstream_dns
listen-address=127.0.0.1,$guest_ip
bind-interfaces
domain-needed
bogus-priv
no-resolv
EOF

  # OrbStack deliberately masks systemd-resolved and provides its own
  # read-only resolv.conf. Use dnsmasq as the guest resolver and forward
  # non-.test queries to the OrbStack resolver discovered above.
  step_progress "restarting dnsmasq"
  rm -f /etc/systemd/resolved.conf.d/test.conf
  systemctl restart dnsmasq
  rm -f /etc/resolv.conf
  cat > /etc/resolv.conf <<'EOF'
# Managed by fcomrqz/dotfiles.
nameserver 127.0.0.1
options edns0
EOF

  step_progress "verifying public and wildcard DNS"
  getent hosts example.com >/dev/null || {
    log_error "dnsmasq cannot reach OrbStack's upstream DNS resolver."
    return 1
  }
  getent hosts doctor.test >/dev/null || {
    log_error "dnsmasq did not resolve the wildcard .test domain."
    return 1
  }
}

configure_caddy() {
  step_progress "installing the Caddy configuration"
  install -o root -g caddy -m 0640 "$DOTFILES_ROOT/caddy/caddy.json" /etc/caddy/caddy.json
  install -d -o root -g root -m 0755 /etc/systemd/system/caddy.service.d
  cat > /etc/systemd/system/caddy.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/caddy.json
ExecReload=
ExecReload=/usr/bin/caddy reload --config /etc/caddy/caddy.json --force
EOF
  step_progress "enabling and restarting Caddy"
  systemctl daemon-reload
  systemctl enable --now caddy
  systemctl restart caddy

  # Asking for the default CA provisions it even before the first dynamic
  # application route is registered.
  step_progress "waiting for Caddy's local certificate authority"
  for _ in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:2019/pki/ca/local >/dev/null; then
      trust_caddy_ca
      return 0
    fi
    sleep 1
  done
  log_error "Caddy started, but its local CA was not provisioned."
  return 1
}

install_github_app_authentication() {
  local target_user="$1"
  local target_group

  target_group="$(id -gn "$target_user")"
  step_progress "installing credential helper commands"
  install -d -o root -g root -m 0755 /usr/local/libexec/fcomrqz
  install -o root -g root -m 0644 \
    "$DOTFILES_ROOT/bin/github-app-token-common" \
    /usr/local/libexec/fcomrqz/github-app-token-common
  install -o root -g root -m 0755 \
    "$DOTFILES_ROOT/bin/github-token-store" \
    /usr/local/libexec/fcomrqz/github-token-store
  install -o root -g root -m 0755 \
    "$DOTFILES_ROOT/bin/git-credential-github-app" \
    /usr/local/bin/git-credential-github-app
  install -o root -g root -m 0755 \
    "$DOTFILES_ROOT/bin/gh-github-app" \
    /usr/local/bin/gh

  # /run is a tmpfs. Recreate only the narrow, user-owned token directory on
  # every boot; the macOS helper repopulates its contents through ORBENV.
  step_progress "configuring the runtime token directory"
  {
    printf '# Managed by fcomrqz/dotfiles.\n'
    printf 'd /run/fcomrqz-github-app 0711 root root -\n'
    printf 'd /run/fcomrqz-github-app/%s 0700 %s %s -\n' \
      "$target_user" "$target_user" "$target_group"
  } > /etc/tmpfiles.d/fcomrqz-github-app.conf
  systemd-tmpfiles --create /etc/tmpfiles.d/fcomrqz-github-app.conf
}

install_codex_system_configuration() {
  install -d -o root -g root -m 0755 /etc/codex
  install -o root -g root -m 0644 \
    "$DOTFILES_ROOT/codex/requirements.toml" \
    /etc/codex/requirements.toml
  install -o root -g root -m 0644 \
    "$DOTFILES_ROOT/codex/managed_config.toml" \
    /etc/codex/managed_config.toml
}

trust_caddy_ca() {
  require_root
  install -o root -g root -m 0644 \
    /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt \
    /usr/local/share/ca-certificates/orbstack-development-ca.crt
  update-ca-certificates >/dev/null
}

link_linux_configuration() {
  local config_root="$1"

  step_progress "installing trusted Codex configuration"
  install -d -m 0700 "$HOME/.codex"
  install -d -m 0700 "$HOME/.config/fcomrqz/secrets"
  ensure_dir "$HOME/.local/bin"
  # Install trusted copies instead of links into an agent-editable checkout.
  # Changes to either security boundary take effect only after provisioning.
  install -m 0755 "$DOTFILES_ROOT/bin/with-secrets" \
    "$HOME/.local/bin/with-secrets"
  install -m 0600 "$DOTFILES_ROOT/codex/config.toml" \
    "$HOME/.codex/config.toml"
  if [[ -f "$HOME/.codex/auth.json" ]]; then
    chmod 0600 "$HOME/.codex/auth.json"
  fi

  step_progress "linking Fish, Git, and GitHub CLI"
  ensure_dir "$HOME/.config/fish/themes"
  prepare_fish_configuration
  safe_link "$config_root/fish/functions" "$HOME/.config/fish/functions"
  safe_link "$config_root/fish/config.fish" "$HOME/.config/fish/config.fish"
  safe_link "$config_root/fish/themes/alavesper.theme" "$HOME/.config/fish/themes/alavesper.theme"
  safe_link "$config_root/git/.gitconfig" "$HOME/.gitconfig"
  ensure_dir "$HOME/.config/git"
  safe_link "$config_root/git/attributes" "$HOME/.config/git/attributes"
  safe_link "$config_root/git/linux.gitconfig" "$HOME/.config/git/platform.gitconfig"
  ensure_dir "$HOME/.config/gh"
  safe_link "$config_root/gh/config.yml" "$HOME/.config/gh/config.yml"

  step_progress "linking Micro"
  ensure_dir "$HOME/.config/micro"
  safe_link "$config_root/micro/settings.json" "$HOME/.config/micro/settings.json"
  safe_link "$config_root/micro/bindings.json" "$HOME/.config/micro/bindings.json"
  safe_link "$config_root/micro/syntax" "$HOME/.config/micro/syntax"
  safe_link "$config_root/micro/colorschemes" "$HOME/.config/micro/colorschemes"
}

install_system() {
  local target_user="${1:?target user is required}"
  local guest_ip="${2:?guest IPv4 address is required}"
  local arch

  require_root
  arch="$(linux_arch)"

  export DEBIAN_FRONTEND=noninteractive
  log_section "Installing Linux system packages"
  # A previous interrupted run may have written the Caddy source before its
  # keyring. Repair that state before the first apt update so provisioning is
  # safely resumable.
  if [[ -f /etc/apt/sources.list.d/caddy-stable.list ]]; then
    run_step "Repairing the Caddy package repository" \
      install_caddy_repository
  fi
  run_step "Refreshing the Ubuntu package index" apt-get update
  run_step "Installing base development packages" apt-get install -y \
    ca-certificates curl dnsmasq ffmpeg fish git gnupg jq micro \
    nodejs npm ripgrep shellcheck sqlite3 tar unzip xz-utils

  run_step "Installing Playwright system dependencies" \
    install_playwright_dependencies

  run_step "Configuring the Caddy package repository" \
    install_caddy_repository
  run_step "Refreshing the package index for Caddy" apt-get update
  run_step "Installing the Caddy web server" apt-get install -y caddy
  run_step "Installing managed Codex system policy" \
    install_codex_system_configuration

  log_section "Installing Linux command-line tools"
  case "$arch" in
    arm64)
      install_github_deb_step cli/cli 'gh_.*_linux_arm64\.deb$' gh "GitHub CLI"
      install_github_deb_step dandavison/delta 'git-delta_.*_arm64\.deb$' git-delta "Git Delta"
      install_github_deb_step cloudflare/cloudflared 'cloudflared-linux-arm64\.deb$' cloudflared "Cloudflare Tunnel"
      install_github_archive_binary_step stripe/stripe-cli 'stripe_.*_linux_arm64\.tar\.gz$' stripe "Stripe CLI"
      install_github_archive_binary_step boyter/scc 'scc_Linux_arm64\.tar\.gz$' scc "SCC code counter"
      ;;
    amd64)
      install_github_deb_step cli/cli 'gh_.*_linux_amd64\.deb$' gh "GitHub CLI"
      install_github_deb_step dandavison/delta 'git-delta_.*_amd64\.deb$' git-delta "Git Delta"
      install_github_deb_step cloudflare/cloudflared 'cloudflared-linux-amd64\.deb$' cloudflared "Cloudflare Tunnel"
      install_github_archive_binary_step stripe/stripe-cli 'stripe_.*_linux_x86_64\.tar\.gz$' stripe "Stripe CLI"
      install_github_archive_binary_step boyter/scc 'scc_Linux_x86_64\.tar\.gz$' scc "SCC code counter"
      ;;
  esac

  log_section "Configuring Linux services"
  run_step "Installing GitHub App authentication" \
    install_github_app_authentication "$target_user"
  run_step "Configuring local development DNS" configure_dns "$guest_ip"
  run_step "Configuring the Caddy HTTPS proxy" configure_caddy
  run_step "Setting Fish as the default shell" \
    chsh -s "$(command -v fish)" "$target_user"
}

install_user() {
  local config_root="${1:-$DOTFILES_ROOT}"
  require_non_root

  log_section "Configuring the Linux user"
  run_step "Installing Linux user configuration" \
    link_linux_configuration "$config_root"

  if ! command_exists flyctl; then
    run_step "Installing Fly CLI" \
      /bin/bash -c 'curl -L https://fly.io/install.sh | sh'
  else
    log_skip "Fly CLI is already installed"
  fi
  install_bun
  if ! codex_supports_managed_sandbox; then
    run_step "Installing Codex CLI with managed sandbox support" \
      /bin/bash -c \
      'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'
  else
    log_skip "Codex CLI with managed sandbox support is already installed"
  fi

  log_success "Linux user configuration is complete."
}

lock_down_user() {
  local target_user="${1:?target user is required}"
  require_root

  step_progress "removing sudo group membership"
  if id -nG "$target_user" \
    | grep -Eq '(^|[[:space:]])sudo([[:space:]]|$)'; then
    gpasswd -d "$target_user" sudo
  fi

  # OrbStack/cloud-init may add an explicit passwordless rule. Remove only
  # lines that grant this exact user sudo access; never edit /etc/sudoers.
  step_progress "removing explicit sudoers grants"
  local file
  for file in /etc/sudoers.d/*; do
    [[ -f "$file" ]] || continue
    if grep -Eq "^[[:space:]]*${target_user}[[:space:]]" "$file"; then
      sed -i "/^[[:space:]]*${target_user}[[:space:]]/d" "$file"
      if ! grep -Eq '^[[:space:]]*[^#[:space:]]' "$file"; then
        rm -f "$file"
      fi
    fi
  done
  step_progress "validating sudoers"
  visudo -cf /etc/sudoers >/dev/null
}

usage() {
  cat <<'EOF'
Usage:
  install/linux.sh system USER GUEST_IPV4
  install/linux.sh user [CONFIG_ROOT]
  install/linux.sh dns GUEST_IPV4
  install/linux.sh trust-ca
  install/linux.sh lockdown USER
EOF
}

case "${1:-user}" in
  system)
    shift
    install_system "$@"
    ;;
  user)
    shift
    install_user "$@"
    ;;
  dns)
    shift
    require_root
    run_step "Configuring local development DNS" \
      configure_dns "${1:?guest IPv4 address is required}"
    ;;
  trust-ca)
    shift
    run_step "Trusting Caddy's local certificate authority" trust_caddy_ca
    ;;
  lockdown)
    shift
    run_step "Removing Linux administrative access" lock_down_user "$@"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
