# Remnawave Manager

[English](README.md) · [Русский](README.ru.md)

Production installer for [Remnawave](https://docs.rw) on Debian/Ubuntu. Interactive menu with a description of every function. UI language: **English** or **Russian**.

**Current version:** `25.2.7-prod`

Main line: **booarkz-cpu**. Extra behaviour comes from [Rezzosoft KVN](https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2), [eGamesAPI](https://github.com/eGamesAPI/remnawave-reverse-proxy) and [DigneZzZ](https://github.com/DigneZzZ/remnawave-scripts). Original authorship is kept — see [CREDITS.md](CREDITS.md).

The Xray profile, inbounds, nodes, hosts, **CorgiLusi** squad and CorgiLusi user are created through the Remnawave API. Each node gets its own config profile. **Default-Profile** is removed from internal squads after install.

## Quick start

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.7-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh
```

No arguments opens the menu. Do not type `sudo` — the script raises root itself. On first run it asks for **English** or **Русский** (saved in `/opt/remnawave/manager.env`). Switch later with menu item 22 or:

```bash
bash remnawave-manager.sh --lang en
bash remnawave-manager.sh --lang ru
```

By default every transport is enabled: Reality, Hysteria2, gRPC and xHTTP.

## Menu (all functions)

| # | Function | What it does |
| --- | --- | --- |
| 1 | Full install | Panel + node on one VPS, nginx SNI, Corgi SelfSteal, certificates, API bind |
| 2 | Panel only | Panel + subscription page + HTTPS; `EDGE_ADDRESS` registers the node now |
| 3 | Node only | Host-network remnanode, Reality SNI site; `SECRET_KEY` from panel `credentials.txt` |
| 4 | Auto-bind protocols | Per-node CorgiLusi profile, CorgiLusi squad, delete Default-Profile |
| 5 | Status | Containers, nginx/fail2ban, systemd timers |
| 6 | Doctor | Panel API, subscription page, ports, UFW |
| 7 | Repair | Rewrite proxy headers and SelfSteal without wiping Docker/DB |
| 8 | Logs | Follow remnawave / remnanode / subscription-page |
| 9 | Up | `docker compose up` for every stack |
| 10 | Down | `docker compose down` (data kept) |
| 11 | Restart | Restart every Remnawave compose stack |
| 12 | Backup | Archive under `/var/backups/remnawave` |
| 13 | Restore | Restore a `.tgz` or `.age` archive |
| 14 | Update | Backup, pull images (panel → node → subscription), verify API |
| 15 | Uninstall | Remove services and nginx vhosts; backups stay |
| 16 | Xray core | Custom binary or restore the image builtin |
| 17 | Add-ons | DigneZzZ CLI, SelfSteal, WARP/Tor, NetBird, eGames reverse-proxy |
| 18 | Stealth login | Cookie/query gate for `/auth/login` (eGames idea) |
| 19 | Install CLI | Copy to `/usr/local/bin/remnawave-manager` |
| 20 | Converter | Optional Rezzosoft JSON helper (not required to bind) |
| 21 | Credits / help | Authorship and full CLI help |
| 22 | Language | English or Русский |
| 23 | URLs | Panel / subscription / SNI and CorgiLusi user link (passwords stay in `credentials.txt`) |
| 0 | Exit | — |

## Install modes

| Command | What is installed |
| --- | --- |
| `install single` | Panel + node on one VPS |
| `install panel` | Panel only; nodes connect later |
| `install node` | Node on a separate server (`SECRET_KEY` from `/opt/remnawave/credentials.txt` on the panel) |

Two servers:

```bash
# Panel (EDGE_ADDRESS is the node IP so the Node card is created immediately)
bash remnawave-manager.sh --lang en install panel --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com \
  EDGE_ADDRESS=203.0.113.20

# Node (other VPS)
bash remnawave-manager.sh --lang en install node --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY='secret_from_credentials.txt'
```

## Protocols

All on by default. Binding is automatic.

- Reality (VLESS TCP, SNI on 443)
- Hysteria2 UDP/443 in the Xray profile + sing-box UDP/8443
- VLESS gRPC + Reality TCP/8443
- VLESS xHTTP + Reality TCP/4443

Flags: `--all-protocols` (same as default), `--reality-only`, `--hysteria2`, `--grpc`, `--xhttp`.

On an existing system: `bash remnawave-manager.sh protocols` (alias: `bind`) or menu item 4.

## Maintenance CLI

The header of the menu shows live local health (panel API, subscription `:3010`, remnanode). If the VPS already has Remnawave, items 1–3 offer **repair**, **re-bind**, or full reinstall instead of blindly running `apt full-upgrade` again.

On HTTP 502 for the subscription page: menu **7 (repair)** or `bash remnawave-manager.sh repair`. Do not paste PowerShell scripts onto the Linux VPS.

`status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `urls`, `health`, `core-update`, `stealth`, `addon remnawave|remnanode|selfsteal|wtm|netbird|egames`.

Details: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md), [CHANGELOG.md](CHANGELOG.md), [SHA256SUMS](SHA256SUMS).
