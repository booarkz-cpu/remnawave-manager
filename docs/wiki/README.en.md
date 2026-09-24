# Remnawave Manager — Wiki

Remnawave Manager is a Bash CLI manager for deploying, configuring, maintaining and updating Remnawave Panel and Remnawave Node.

Author: **Corgi Lusi**

## Installation

```bash
remnawave-manager install single
remnawave-manager install panel
remnawave-manager install node
```

Recommended prerequisites:

- Debian/Ubuntu;
- public IPv4;
- Panel domain;
- subscription domain;
- Reality/SNI domain;
- TCP ports `80` and `443` available;
- email for Let's Encrypt.

## Main menu

| # | Function | CLI |
|---:|---|---|
| 0 | Exit | — |
| 1 | Full installation | `install single` |
| 2 | Panel only | `install panel` |
| 3 | Node only | `install node` |
| 4 | Auto-bind / protocols | `protocols`, `bind` |
| 5 | Status | `status` |
| 6 | Doctor | `doctor` |
| 7 | Repair | `repair` |
| 8 | Logs | `logs` |
| 9 | Up | `up` |
| 10 | Down | `down` |
| 11 | Restart | `restart` |
| 12 | Backup | `backup` |
| 13 | Restore | `restore` |
| 14 | Remnawave update | `update` |
| 15 | Uninstall | `uninstall` |
| 16 | Xray Core | `core-update` |
| 17 | Add-ons | `addon` |
| 18 | Stealth Login | `stealth` |
| 19 | Install CLI | `install-script` |
| 20 | Converter | `converter` |
| 21 | Help / Credits | — |
| 22 | Language | — |
| 23 | URLs | — |
| 24 | Community Update | `community-update` |
| 25 | Node transports | `node-transports` |
| 26 | Manager update | `check-update`, `self-update` |
| 27 | Add Node | `add-node` |
| 28 | Users | `users` |
| 29 | Nodes | `nodes` |
| 30 | Alerts / Remote backup | `telegram`, `backup-remote` |
| 31 | Certificates | `certs` |
| 32 | Firewall | `firewall` |
| 33 | Subscription Stub | `sub-stub` |

## Supported transports

- VLESS Reality TCP — `443`;
- Hysteria2 UDP — `443`;
- sing-box UDP — `8443`;
- VLESS gRPC Reality TCP — `8443`, path `/grpc`;
- VLESS xHTTP Reality TCP — `4443`, path `/xhttp`.

Installation flags:

```text
--all-protocols
--reality-only
--hysteria2
--grpc
--xhttp
```

Full transport rebind:

```bash
remnawave-manager protocols
remnawave-manager bind
```

## Diagnostics

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
remnawave-manager repair
remnawave-manager restart
```

## Backups

```bash
remnawave-manager backup
remnawave-manager restore
```

Backup directory:

```text
/var/backups/remnawave/
```

Remote backup and Telegram integrations:

```bash
remnawave-manager telegram
remnawave-manager backup-remote
```

## Updates

Manager:

```bash
remnawave-manager check-update
remnawave-manager self-update
```

Remnawave:

```bash
remnawave-manager update
```

Xray:

```bash
remnawave-manager core-update
```

## Important paths

```text
/opt/remnawave/
/opt/remnawave/subscription/
/opt/remnawave/node/
/opt/remnawave-edge/
/opt/remnawave/hysteria2/
/opt/remnawave-addons/
/var/backups/remnawave/
/var/log/remnawave-manager.log
/var/www/sub-site/
/usr/local/bin/remnawave-manager
```

## Security

Never commit or publish:

- API tokens;
- `SECRET_KEY`;
- PostgreSQL passwords;
- `credentials.txt`;
- age private keys;
- Telegram Bot Tokens;
- TLS private keys;
- `.env` secrets.

Do not expose the internal Panel port `3000` directly unless explicitly required and secured. Use nginx/reverse proxy and correct forwarded headers.
