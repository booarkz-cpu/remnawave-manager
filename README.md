# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.15-prod`

## Quick start

Download via jsDelivr (GitHub Releases may 504 from some VDS):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.15-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

`remnawave-manager.sh` is a copy of `remnawave-manager-v25.1.15-prod.sh`.

Expected SHA256: `15ad868699b467264ffda6354b94cf9fc6961b02569adcce36c480c131464835`

## 25.1.15-prod

Ubuntu 24.04 nginx 1.24 rejects standalone `http2 on;`. Listen lines use `ssl http2` again.

If panel/subscription still return 502:

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.15-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 15ad868699b467264ffda6354b94cf9fc6961b02569adcce36c480c131464835
grep "VERSION=" remnawave-manager.sh | head -1
# нужно: VERSION='25.1.15-prod'
sudo bash remnawave-manager.sh repair
```

The log must say `repair: Remnawave Manager 25.1.15-prod`.

## Runtime

Proxy-aware internal API requests:

```text
X-Forwarded-For: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Host: <Panel domain>
Host: <Panel domain>
X-Remnawave-Client-Type: browser
```

## Production status

**Static audit:** green.

Details: [CHANGELOG.md](CHANGELOG.md), [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md), [SHA256SUMS](SHA256SUMS).
