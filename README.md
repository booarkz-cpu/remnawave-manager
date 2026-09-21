# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.16-prod`

## Quick start

Download via jsDelivr (GitHub Releases may 504 from some VDS):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.16-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

`remnawave-manager.sh` is a copy of `remnawave-manager-v25.1.16-prod.sh`.

Expected SHA256: `b3d8293bb4735f48b21e456860585a80e9c9a8102f33c5b8917b8bac259197b8`

## 25.1.16-prod

Panel HTTP 200 after 25.1.15, subscription still 502: `repair` did not recreate `remnawave-subscription-page`. The container exits if its API token cannot read `/system/metadata`. `CUSTOM_SUB_PREFIX=sub` also hid the UI at `/`.

If subscription still returns 502:

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.16-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: b3d8293bb4735f48b21e456860585a80e9c9a8102f33c5b8917b8bac259197b8
grep "VERSION=" remnawave-manager.sh | head -1
# нужно: VERSION='25.1.16-prod'
sudo bash remnawave-manager.sh repair
```

The log must say `repair: Remnawave Manager 25.1.16-prod`. Then `curl -I https://sb.example.com` should be HTTP 200.

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
