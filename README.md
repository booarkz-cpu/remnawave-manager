# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.12-prod`

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

`remnawave-manager.sh` is a copy of `remnawave-manager-v25.1.12-prod.sh`.

## 25.1.12-prod

Fixes a live single-VDS install where the panel and subscription page returned HTTP 502 and the Reality SNI site was a generic stub.

- nginx no longer uses Ubuntu `proxy_params`; it sends the official Remnawave reverse-proxy headers (`Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host`) plus HTTP/1.1 so ProxyCheckMiddleware does not destroy the upstream socket;
- SSL snippets live in `/etc/nginx/snippets/` so Ubuntu does not auto-include them twice from `conf.d/`;
- default SelfSteal camouflage is a Corgi Lusi kennel site (`--selfsteal-template corgi|simple|business|nothing`);
- `repair` rewrites nginx and the masking site on an already installed VDS without touching Docker/DB;
- SSH port detection no longer trips `set -o pipefail` via `head` SIGPIPE.

If you already installed `25.1.11-prod`:

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

**Real VDS runtime test:** `repair` is the supported fix for 25.1.11 502s.

## SHA256

```text
45e5029aa29f21b587a2726bdf191305ab4fd855e85548b73e010e8982bec3bb  remnawave-manager-v25.1.12-prod.sh
```

Details: [CHANGELOG.md](CHANGELOG.md), [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).
