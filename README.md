# Remnawave Manager

Production-oriented Bash manager for deploying and maintaining Remnawave on Debian/Ubuntu.

**Current version:** `25.1.10-prod`

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/v25.1.10-prod/remnawave-manager-v25.1.10-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## 25.1.10-prod

Firewall/SSH bootstrap hotfix plus automatic OS update during installation:

- fixed SSH port detection when `sshd -T` returns no `port`;
- added fallbacks for `sshd_config`, systemd socket activation and safe default `22`;
- UFW opens all detected SSH ports before enabling the firewall;
- before installing system dependencies, the installer runs `apt-get update`, `dpkg --configure -a`, `apt-get -f install`, `apt-get full-upgrade`, `autoremove --purge` and `autoclean`;
- automatic reboot is disabled; when `/var/run/reboot-required` exists, the installer reports that a reboot is required;
- Bootstrap/API token fixes from 25.1.7 and 25.1.8 are preserved.

## 25.1.8-prod

Bootstrap/API token compatibility hotfix:

- automatic API token name stays within backend `name <= 30`;
- added token-name length validation before the API request;
- fixed bootstrap of the minimal API token for Subscription Page;
- bootstrap persistence fixes from 25.1.7 are preserved.

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

**Real VDS runtime test:** completed on Ubuntu 24.04; single-VDS installation reached `Single VDS installed`.

## SHA256

```text
97a9a6cdfb5d203c35e43eee87ef8977ec34e3054a9fa5ca64dfc031fedb925  remnawave-manager-v25.1.10-prod.sh
```

Details: [CHANGELOG.md](CHANGELOG.md).
