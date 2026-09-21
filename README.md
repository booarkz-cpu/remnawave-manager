# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.11-prod`

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
sudo bash remnawave-manager.sh install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
sudo bash remnawave-manager.sh install single --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

`remnawave-manager.sh` is a copy of `remnawave-manager-v25.1.11-prod.sh`.

## 25.1.11-prod

Installer bugfixes on top of the 25.1.10 OS-upgrade release:

- same-server Node is registered via the `remnawave-network` Docker gateway, not `127.0.0.1`;
- `install panel` publishes HTTPS on TCP/443 through the SNI router;
- Hysteria2 starts as `sing-box run -c`;
- Prometheus scrapes host-network node-exporter at `host.docker.internal:9100`;
- nginx `ssl_reject_handshake` has a fallback for 1.18;
- panel `.env` sets `REDIS_SOCKET` for Valkey;
- `manager.env` is updated with upsert, so reruns keep tokens;
- OS `apt-get full-upgrade` from 25.1.10 is unchanged (no automatic reboot).

## Runtime

`25.1.6+` uses proxy-aware internal API requests:

```text
X-Forwarded-For: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Host: <Panel domain>
Host: <Panel domain>
X-Remnawave-Client-Type: browser
```

## Production status

**Static audit:** green.

**Real VDS runtime test:** required on the target server after 25.1.11.

## SHA256

```text
e10193fd771c386af76697b0bc42c1eddb831b21cf1d60341f6f6fe43269d239  remnawave-manager-v25.1.11-prod.sh
```

Details: [CHANGELOG.md](CHANGELOG.md), [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).
