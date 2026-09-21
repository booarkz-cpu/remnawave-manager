# Remnawave Manager

[English](README.md) · [Русский](README.ru.md)

**Full instruction:** [English guide](docs/GUIDE.en.md) · [Русская инструкция](docs/GUIDE.ru.md)

Production installer for [Remnawave](https://docs.rw) on Debian/Ubuntu. Interactive menu with a description of every function. UI: **English** or **Russian**.

**Current version:** `1.4.4`

Author: **Corgi Lusi (Корги Люси)**. Extra behaviour comes from [Rezzosoft KVN](https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2), [eGamesAPI](https://github.com/eGamesAPI/remnawave-reverse-proxy) and [DigneZzZ](https://github.com/DigneZzZ/remnawave-scripts). Original authorship is kept — [CREDITS.md](CREDITS.md).

The Xray profile, inbounds, nodes, hosts, **CorgiLusi** squad and CorgiLusi user are created through the Remnawave API. Each node gets its own config profile. **Default-Profile** is removed after install. You do not edit the panel UI to bind protocols.

Two different updates:

| | Script file | Remnawave images |
| --- | --- | --- |
| What | `remnawave-manager.sh` | panel / node / subscription containers |
| How | [Update this script](#update-this-script-to-latest) | menu **14** / `update` |

---

## Contents

- [Quick start](#quick-start)
- [Update this script to Latest](#update-this-script-to-latest)
- [Menu](#menu)
- [Install modes](#install-modes)
- [Protocols](#protocols)
- [Maintenance](#maintenance)
- [Documentation](#documentation)

---

## Quick start

Download **GitHub Latest** (not `raw.githubusercontent.com/main`) and check the hash:

```bash
curl -fL --retry 5 --retry-all-errors \
  https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh

curl -fL --retry 5 --retry-all-errors \
  https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/SHA256SUMS \
  -o SHA256SUMS
sha256sum remnawave-manager.sh
grep ' remnawave-manager.sh$' SHA256SUMS
```

The two hashes must match. Then:

```bash
bash remnawave-manager.sh
```

No arguments opens the menu. Do not type `sudo` — the script raises root itself. On first run it asks for **English** or **Русский** (saved in `/opt/remnawave/manager.env`). Switch later with menu item 22 or `--lang en|ru`.

Pinned 1.4.4 via jsDelivr (optional):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.4.4/remnawave-manager.sh \
  -o remnawave-manager.sh
# sha256: c94a44bf4c9e5930593bfe2227b14fed1e495efd72d300ba857aa10778d37a0d
```

By default every transport is enabled: Reality, Hysteria2, gRPC and xHTTP.

Step-by-step (one VPS, two VPS, DNS, files on disk): **[docs/GUIDE.en.md](docs/GUIDE.en.md)**.

---

## Update this script to Latest

This replaces **only** the installer file. It does not pull Docker images and does not wipe the panel database. Image updates are menu **14**.

First look at the help header: `bash remnawave-manager.sh --help` (line “Corgi Lusi · Remnawave Manager …”).

### 1.1.0 or 1.2.0 — you do not have `check-update`

If `bash remnawave-manager.sh check-update` prints the **full help** and the header says `1.1.0` / `1.2.0`, that is expected: `check-update` exists only from 1.3.0. 1.1.0 already has `self-update`. On the VPS run:

```bash
bash remnawave-manager.sh self-update
```

It downloads GitHub Latest, runs `bash -n`, replaces this file (and `/usr/local/bin/remnawave-manager` if the CLI was installed), then restarts. The header should then show `1.4.0` or newer. `check-update` works only after that.

If there is no `self-update` (1.0.0 / 25.2.x) or GitHub is unreachable, download Latest by hand as in [Quick start](#quick-start) and compare SHA256.

### Already on 1.3.0 or newer

The menu checks GitHub Latest (at most every 6 hours) and asks to install. Or:

```bash
bash remnawave-manager.sh check-update
bash remnawave-manager.sh check-update --apply
bash remnawave-manager.sh --version
```

Same thing: menu **26**, or `self-update` again. Menu **24** still refreshes author modules (and still has a shortcut to this script). Skip the query: `--no-update-check`. Check only: menu **26** → **1**, or `check-update`. Unknown commands no longer dump the full help (from 1.4.0).

Run the script update on **both** VPS (panel and node). If you used menu **19**, after a manual `curl` run `bash remnawave-manager.sh install-script`.

### After the file is updated

You usually do **not** reinstall Remnawave.

| Goal | Next step |
| --- | --- |
| HTTP 502 | menu **7** / `repair` |
| Rebuild CorgiLusi bind | menu **4** / `protocols` (panel) |
| Add/remove gRPC, xHTTP, Hysteria2 | menu **25** (panel), then `node-transports apply` on the node |
| New Remnawave images | menu **14** / `update` |

Do **not**: download from `raw.githubusercontent.com/main`; run item **1** “to get a new script”; treat item **14** as a script update; paste PowerShell onto Linux.

Full text: [docs/GUIDE.en.md §10](docs/GUIDE.en.md#10-how-to-update-this-script-to-latest).

---

## Menu

| # | Function | What it does |
| --- | --- | --- |
| 1 | Full install | Panel + node on one VPS, nginx SNI, Corgi, certs, API bind |
| 2 | Panel only | Panel + subscription HTTPS; `EDGE_ADDRESS` registers the node |
| 3 | Node only | Host-network remnanode, Reality SNI; `SECRET_KEY` from panel `credentials.txt` |
| 4 | Auto-bind protocols | Per-node CorgiLusi profile, CorgiLusi squad, drop Default-Profile |
| 5 | Status | Containers, nginx/fail2ban, systemd timers |
| 6 | Doctor | Panel API, subscription page, certs, listen ports, node Connected, UFW |
| 7 | Repair | Rewrite proxy headers and SelfSteal without wiping Docker/DB |
| 8 | Logs | Follow remnawave / remnanode / subscription-page |
| 9 | Up | `docker compose up` for every stack |
| 10 | Down | `docker compose down` (data kept) |
| 11 | Restart | Restart every Remnawave compose stack |
| 12 | Backup | Archive under `/var/backups/remnawave` |
| 13 | Restore | Restore a `.tgz` or `.age` archive |
| 14 | Update | Backup, pull **Remnawave images**, verify API |
| 15 | Uninstall | Remove services and nginx vhosts; backups stay |
| 16 | Xray core | Custom binary or restore the image builtin |
| 17 | Add-ons | DigneZzZ CLI, SelfSteal, WARP/Tor, NetBird, eGames |
| 18 | Stealth login | Cookie/query gate for `/auth/login` |
| 19 | Install CLI | Copy to `/usr/local/bin/remnawave-manager` |
| 20 | Converter | Optional Rezzosoft JSON helper (not required to bind) |
| 21 | Credits / help | Authorship and full CLI help |
| 22 | Language | English or Русский |
| 23 | URLs | Panel / subscription / SNI and CorgiLusi user link |
| 24 | Author updates | Refresh upstream modules (this script: item **26**) |
| 25 | Node transports | Add or remove xHTTP, gRPC, Hysteria2 on an already-installed node |
| 26 | This script | Check / install GitHub Latest of this installer |
| 27 | Add a node | Register another node via API — no OS upgrade, no menu 1 |
| 0 | Exit | — |

---

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

Details: [docs/GUIDE.en.md](docs/GUIDE.en.md#6-install-panel-and-node-on-two-servers).

---

## Protocols

All on by default. Binding is automatic.

- Reality (VLESS TCP, SNI on 443, host fingerprint **firefox**)
- Hysteria2 UDP/443 in the Xray profile + sing-box UDP/8443
- VLESS gRPC + Reality TCP/8443
- VLESS xHTTP + Reality TCP/4443

Flags: `--all-protocols` (same as default), `--reality-only`, `--hysteria2`, `--grpc`, `--xhttp`.

On an existing system, **full** re-bind: `bash remnawave-manager.sh protocols` (alias: `bind`) or menu item **4**.

To **add or remove** extras on a node that is already up (panel and node may be on different VPS), use a **separate** item — menu **25**. If several nodes exist, the menu asks which UUID (`0` = all).

```bash
# Panel
bash remnawave-manager.sh node-transports add grpc|xhttp|hysteria2|all
bash remnawave-manager.sh node-transports remove grpc|xhttp|hysteria2|all
bash remnawave-manager.sh node-transports reality-only

# Node VPS
bash remnawave-manager.sh node-transports apply
```

---

## Maintenance

The menu header shows live local health (panel API, subscription `:3010`, remnanode) and, after a GitHub check, whether the script itself is up to date.

On HTTP 502: menu **7** or `bash remnawave-manager.sh repair`. Do not paste PowerShell onto the Linux VPS.

CLI: `status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `urls`, `health`, `core-update`, `stealth`, `addon …`, `node-transports …`, `add-node`, `check-update`, `self-update`, `--version`.

---

## Documentation

| | English | Русский |
| --- | --- | --- |
| Full guide | [docs/GUIDE.en.md](docs/GUIDE.en.md) | [docs/GUIDE.ru.md](docs/GUIDE.ru.md) |
| Version journal | [CHANGELOG.md](CHANGELOG.md) | [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md) |
| Checksums | [SHA256SUMS](SHA256SUMS) | same |
| Credits | [CREDITS.md](CREDITS.md) | same |
| Releases | [GitHub Latest](https://github.com/booarkz-cpu/remnawave-manager/releases/latest) | same |
