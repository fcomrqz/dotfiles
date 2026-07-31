# Caddy

Caddy runs inside the isolated OrbStack development machine. The systemd unit
loads `caddy.json`, listens on the machine's HTTPS port, and leaves the route
array empty for applications to update through the admin API.

## Networking

- `dnsmasq` resolves every `*.test` name to the isolated machine's IPv4 address.
- Caddy accepts HTTPS on port 443.
- OrbStack machine-port exposure to the LAN is disabled.
- The admin API is available only inside the machine at `127.0.0.1:2019`.
- Application processes register mappings such as
  `my-feature.test -> 127.0.0.1:4173`.
- OrbStack is created with host integration, mounts, SSH-agent forwarding, and
  cross-machine networking disabled.

The `pki` application provisions an internal development CA. The machine
manager adds its root certificate to Linux's trust store and the macOS System
keychain; the private key never leaves Linux.

## Dynamic routes

The existing Caddy JSON API remains the routing interface. For example, an
application can add a reverse-proxy route to the `local` server with:

```sh
curl -X POST \
  -H 'Content-Type: application/json' \
  http://127.0.0.1:2019/config/apps/http/servers/local/routes \
  --data '{
    "@id": "example.test",
    "match": [{"host": ["example.test"]}],
    "handle": [{
      "handler": "reverse_proxy",
      "upstreams": [{"dial": "127.0.0.1:3000"}]
    }]
  }'
```

Delete it later through its ID:

```sh
curl -X DELETE http://127.0.0.1:2019/id/example.test
```

## Verification

Inside the machine:

```sh
systemctl status caddy dnsmasq systemd-resolved
curl http://127.0.0.1:2019/config/
getent hosts any-name.test
```

From macOS:

```sh
dscacheutil -q host -a name any-name.test
curl https://example.test
```
