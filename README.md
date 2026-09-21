# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.13-prod`

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

`remnawave-manager.sh` is a copy of `remnawave-manager-v25.1.13-prod.sh`.

## 25.1.13-prod

Hotfix for `repair` on a 25.1.11 VDS: 25.1.12 deleted `/etc/nginx/conf.d/ssl-params.conf` before rewriting `reality-site.conf`, so `nginx -t` failed and the 502/Corgi changes never applied.

- leftover `include /etc/nginx/conf.d/ssl-params.conf` is rewritten to the snippet **before** the old file is removed;
- `repair` writes all nginx files, then reloads once.

If `repair` from 25.1.12 failed with `ssl-params.conf` missing, download 25.1.13 and run `repair` again.

## 25.1.12-prod

Fixes a live single-VDS install where the panel and subscription page returned HTTP 502 and the Reality SNI site was a generic stub.

- nginx no longer uses Ubuntu `proxy_params`; it sends the official Remnawave reverse-proxy headers (`Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host`) plus HTTP/1.1 so ProxyCheckMiddleware does not destroy the upstream socket;
- SSL snippets live in `/etc/nginx/snippets/` so Ubuntu does not auto-include them twice from `conf.d/`;
- default SelfSteal camouflage is a Corgi Lusi kennel site (`--selfsteal-template corgi|simple|business|nothing`);
- `repair` rewrites nginx and the masking site on an already installed VDS without touching Docker/DB;
- SSH port detection no longer trips `set -o pipefail` via `head` SIGPIPE.

If `repair` from 25.1.12 failed with `ssl-params.conf` missing, or you are still on 25.1.11:

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sudo bash remnawave-manager.sh repair
```

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

**Real VDS runtime test:** use 25.1.13 `repair` if 25.1.12 failed on `ssl-params.conf`.

## SHA256

```text
c868a4970404dc9ae37d687f49e780a6de9ee8698115604cde1999c816b7148b  remnawave-manager-v25.1.13-prod.sh
```

Details: [CHANGELOG.md](CHANGELOG.md), [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).
