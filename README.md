# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.14-prod`

## Quick start

Download from **GitHub Releases** (avoids `raw.githubusercontent.com` CDN cache):

```bash
curl -fsSL -L https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh -o remnawave-manager.sh
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

`remnawave-manager.sh` is a copy of `remnawave-manager-v25.1.14-prod.sh`.

## 25.1.14-prod

`repair` on a VDS that already lost `/etc/nginx/conf.d/ssl-params.conf` (failed 25.1.12 run) now recreates a comment-only stub first, so `nginx -t` cannot fail on a missing include. Download via Releases, not cached `raw.githubusercontent.com`.

If panel/subscription still return 502, download via jsDelivr (GitHub Releases may 504 from some VDS, and `raw.githubusercontent.com/main` caches 25.1.12):

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.14-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# e94215cc2dfb6e829ee8af449569d43b0d2f1e910017c8ebc40a1766d9f0e6a0
grep "VERSION=" remnawave-manager.sh | head -1
sudo bash remnawave-manager.sh repair
```

The script must print `repair: Remnawave Manager 25.1.14-prod`. If it does not, you still have an old copy.

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

**Real VDS runtime test:** 25.1.14 `repair` after a failed 25.1.12 run.

## SHA256

```text
e94215cc2dfb6e829ee8af449569d43b0d2f1e910017c8ebc40a1766d9f0e6a0  remnawave-manager-v25.1.14-prod.sh
```

Details: [CHANGELOG.md](CHANGELOG.md), [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).
