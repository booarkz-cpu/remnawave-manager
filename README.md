# Remnawave Manager

[English](README.md) · [Русский](README.ru.md)

**Full instruction:** [English guide](docs/GUIDE.en.md) · [Русская инструкция](docs/GUIDE.ru.md)

Production installer for [Remnawave](https://docs.rw) on Debian/Ubuntu. Interactive menu with a description of every function. UI: **English** or **Russian**.

**Current version:** `1.6.0`

**License:** [MIT](LICENSE) — use, copy, modify, and redistribute with the copyright notice. Original files downloaded by menu **24** stay under their authors’ terms — [CREDITS.md](CREDITS.md).

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
- [Menu](#menu) — [full item-by-item](#1-full-install) · [docs/MENU.en.md](docs/MENU.en.md)
- [Install modes](#install-modes)
- [Protocols](#protocols)
- [Maintenance](#maintenance)
- [Documentation](#documentation)
- [License](#license)

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

No arguments opens a **language picker** (English / Русский), then the menu. Do not type `sudo` — the script raises root itself. Enter keeps the current language (`RW_LANG` in `/opt/remnawave/manager.env`). Switch later with menu item 22 or skip the picker with `--lang en|ru`.

Pinned 1.6.0 via jsDelivr (optional):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.6.0/remnawave-manager.sh \
  -o remnawave-manager.sh
# sha256: e194c5cfed6efc84361fd00dc4d62492cb06395a452af236e73316cd12791416
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

Numbers **1–27** stay; **28–32** were added in 1.5.0. No arguments opens this menu (`bash remnawave-manager.sh`). Do not type `sudo`.

Standalone pages (same text): [docs/MENU.en.md](docs/MENU.en.md) · [Русский](docs/MENU.ru.md).

| # | Function | CLI |
| --- | --- | --- |
| [1](#1-full-install) | Full install | `install single` |
| [2](#2-panel-only) | Panel only | `install panel` |
| [3](#3-node-only) | Node only | `install node` |
| [4](#4-auto-bind-protocols) | Auto-bind protocols | `protocols` / `bind` |
| [5](#5-status) | Status | `status` |
| [6](#6-doctor) | Doctor | `doctor` |
| [7](#7-repair) | Repair | `repair` |
| [8](#8-logs) | Logs | `logs [container]` |
| [9](#9-start-up) | Start (up) | `up` |
| [10](#10-stop-down) | Stop (down) | `down` |
| [11](#11-restart) | Restart | `restart` |
| [12](#12-backup) | Backup | `backup` |
| [13](#13-restore) | Restore | `restore FILE` |
| [14](#14-update-remnawave-images) | Update images | `update` |
| [15](#15-uninstall) | Uninstall | `uninstall` |
| [16](#16-xray-core) | Xray core | `core-update` |
| [17](#17-add-ons) | Add-ons | `addon …` |
| [18](#18-stealth-login) | Stealth login | `stealth` |
| [19](#19-install-cli) | Install CLI | `install-script` |
| [20](#20-converter) | Converter | (URL) |
| [21](#21-credits--help) | Credits / help | `--help` |
| [22](#22-language) | Language | `--lang en\|ru` |
| [23](#23-urls) | URLs | `urls` / `health` |
| [24](#24-author-updates) | Author updates | `community-update` |
| [25](#25-node-transports) | Node transports | `node-transports …` |
| [26](#26-this-script) | This script | `self-update` / `check-update` |
| [27](#27-add-a-node) | Add a node | `add-node` |
| [28](#28-users) | Users | `users …` |
| [29](#29-node-control) | Node control | `nodes …` |
| [30](#30-alerts-and-remote-backup) | Alerts and remote backup | `telegram` / `backup-remote` |
| [31](#31-certificates) | Certificates | `certs [renew]` |
| [32](#32-firewall) | Firewall | `firewall [IPv4]` |
| [0](#0-exit) | Exit | — |

Two updates that look similar and are not: **26** replaces this installer file; **14** pulls Remnawave Docker images.

### 1. Full install

Puts **panel + node on one VPS**.

Asks for panel, subscription and Reality hostnames and an admin email, then which transports to enable (default: Reality + Hysteria2 + gRPC + xHTTP). Runs a preflight (Ubuntu/Debian, DNS, TCP 80/443 free, disk, Docker). Installs packages, `apt-get full-upgrade` (no automatic reboot), fail2ban, BBR, Docker Compose stacks, nginx SNI, Let’s Encrypt, the CorgiLusi user, one config profile per node, inbounds, hosts, the **CorgiLusi** squad, and removes **Default-Profile**. The node uses `network_mode: host`; the Node card address is the `remnawave-network` gateway, not `127.0.0.1`. Writes `/opt/remnawave/credentials.txt` and systemd timers (backup, certs, health).

If Remnawave is already on this VPS, items 1–3 offer **repair**, **re-bind**, or a full reinstall instead of running `apt full-upgrade` again.

Does **not** replace this GitHub script (item **26**) and does **not** pull newer panel images later (item **14**).

### 2. Panel only

Panel + subscription HTTPS on this VPS. No remnanode here. `EDGE_ADDRESS` (node public IP) creates the Node card immediately via API. Copy **Node secret** from `/opt/remnawave/credentials.txt` onto the other VPS and run item **3** there.

### 3. Node only

remnanode in host-network + Reality SNI on a second VPS. Needs `PANEL_IP`, Reality domain, admin email and `NODE_SECRET_KEY` from the panel `credentials.txt`. Opens UFW toward the panel (including node port 2222). Prepares ports and `/dev/shm` certs for the transports you picked.

### 4. Auto-bind protocols

**Full rebuild** of CorgiLusi: per-node config profiles, inbounds, hosts, squad. Drops Default-Profile. Reality hosts use uTLS fingerprint **firefox**. Without a protocol flag this command turns **all** transports on. Surgical add/remove of one extra is item **25**.

### 5. Status

Live local health: Docker containers, nginx, fail2ban, systemd timers. The menu header already shows panel API / `:3010` / remnanode dots; this item prints the long form.

### 6. Doctor

Read-only diagnostics: this script vs GitHub Latest; OS; Docker; `nginx -t`; panel API `/auth/status`; `remnawave-subscription-page` and HTTP `:3010`; public HTTPS; Let’s Encrypt days left (warns under 21); listen TCP 80/443, UDP 443/8443 if Hysteria2, TCP 8443 if gRPC, TCP 4443 if xHTTP; `ss`; each node **Connected** via API; `docker ps`; remnawave timers; UFW.

### 7. Repair

Fixes **HTTP 502** on panel or subscription **without** wiping Docker or PostgreSQL. Rewrites nginx (`X-Forwarded-For`, `X-Forwarded-Proto: https`), subscription compose, SelfSteal. Restores `DOMAIN_*` from disk if `manager.env` only has the language.

### 8. Logs

Follows `docker compose logs -f` for `remnawave`, `remnanode` or `remnawave-subscription-page` (you choose the name).

### 9. Start (up)

`docker compose up` for every Remnawave stack found (panel, node, subscription, Hysteria2, monitoring). Does not install missing stacks.

### 10. Stop (down)

`docker compose down` on those stacks. **Volumes and `/opt/remnawave` stay.** Not uninstall.

### 11. Restart

Restarts every Remnawave compose stack. Does not pull images.

### 12. Backup

Archive under `/var/backups/remnawave` (compose, env, nginx snippets, credentials). Optional age encryption: `/opt/remnawave/backup-age.key`.

### 13. Restore

Restores a `.tgz` or `.age` archive. Age needs the private key on disk. A failed item **14** may restore the latest snapshot by itself.

### 14. Update (Remnawave images)

**Docker images only**, not this `.sh` file. Order: backup → pull panel → node → subscription → Hysteria2 → check panel API → reload nginx. On failure it tries to restore the last backup.

### 15. Uninstall

Type `DELETE` to confirm. Stops compose, disables remnawave systemd timers, removes nginx vhosts and helper scripts. **Backups in `/var/backups/remnawave` stay.** Does not `rm -rf /opt/remnawave`.

### 16. Xray core

Replace the node Xray binary with an official/custom build, or restore the image builtin (`/opt/remnawave/node` or the edge path).

### 17. Add-ons

Upstream helpers (authorship kept):

| Key | What |
| --- | --- |
| **a** | DigneZzZ remnawave CLI — panel helper |
| **b** | DigneZzZ remnanode CLI — node helper |
| **c** | SelfSteal templates |
| **d** | WARP / Tor (`wtm`) |
| **e** | NetBird |
| **f** | eGames reverse-proxy installer |

Binding inbounds is still this manager (items **4** / **25**), not the converter.

### 18. Stealth login

eGames-style gate: `/auth/login` returns 404 until the secret query or cookie is present, then sets an HttpOnly cookie. Prints `https://PANEL/auth/login?KEY=KEY`. Needs the panel nginx vhost.

### 19. Install CLI

Copies this file to `/usr/local/bin/remnawave-manager`. After a manual `curl` of a new script, run this again so PATH matches GitHub Latest.

### 20. Converter

Optional Rezzosoft JSON helper: <https://rezzosoft.ru/converter.html>. **Not required** to install or bind — the API creates profiles, hosts and the squad.

### 21. Credits / help

Corgi Lusi authorship, Rezzosoft / eGames / DigneZzZ credits, and full CLI `--help`.

### 22. Language

**English** or **Русский**, saved as `RW_LANG` in `/opt/remnawave/manager.env` (edge env on a node-only VPS).

### 23. URLs

Panel, subscription, Reality SNI and the CorgiLusi user link. **No passwords, JWT or node secret** until you type **SHOW** — then the panel login is printed once and is **not** written to `/var/log/remnawave-manager.log`. CLI: `admin-login` (then SHOW).

### 24. Author updates

Downloads the **original** Rezzosoft / eGames / DigneZzZ scripts into `/opt/remnawave-addons` and writes `AUTHORS.txt`. Sub-menu: (1) refresh modules, (2) install this script from GitHub Latest, (3) check Latest without download, (0) back.

### 25. Node transports

Add or remove **xHTTP, gRPC, Hysteria2** on a node that is already installed (including another VPS). Adding one transport does not turn the others back on. Reality stays.

1. Pick a node: number, UUID, or **0** = all. **q** = main menu.
2. Then: **[1]** add Hysteria2 · **[2]** add gRPC · **[3]** add xHTTP · **[4]** add all three · **[5–7]** remove one · **[8]** Reality only · **[9]** apply on **this** server (UFW, `/dev/shm` certs, Hysteria2 stack) · **[0]** back to the **node list** · **[q]** main menu.

On the **panel**, 1–8 update profile, inbounds, hosts and squad via API, then print the copy-paste for the node: `bash remnawave-manager.sh node-transports apply`. On the **node** VPS run **[9]** or that command.

### 26. This script

GitHub **Latest of this installer**, not Docker images. (1) check Latest, (2) install now (`self-update`: download, `bash -n`, replace this file and the CLI copy, restart), (0) back. From 1.3.0 the main menu also checks Latest at most every 6 hours.

### 27. Add a node

Registers **another** node on an already-running **panel** via API — no `apt full-upgrade`, no menu **1**. Then on the new VPS run item **3** with the Node secret from `credentials.txt`. Panel VPS only.

### 28. Users

Panel only. List, create with **expiry / traffic cap / device limit**, enable/disable, show the **subscription URL** (not the admin password). Same squad as CorgiLusi. CLI: `users create NAME [DAYS|YYYY-MM-DD] [GB|512M|10G] [DEVICES]`.

### 29. Node control

Disable, enable, restart **one** node (or `0` / `all` for restart), change address (IPv4 or hostname). Pick like item 25. CLI: `nodes list|disable|enable|restart|address`.

### 30. Alerts and remote backup

Enable Telegram (token + chat, test message). Healthcheck then warns at most once an hour if the panel API is down, a cert has < 21 days, or a node is not Connected. rclone+age off-VPS copy (daily 02:00 or run now). Token is not printed in the log.

### 31. Certificates

Days left for panel / sub / Reality. `certbot renew` now, force-renew, copy into `/dev/shm` for Hysteria2. The menu header shows the nearest expiry.

### 32. Firewall

Show UFW, set or clear **ADMIN_IP**, rebuild rules (SSH, 80/443, transport ports, node 2222). Clearing ADMIN_IP allows SSH from any IPv4.

### 33. Subscription stub

Corgi Lusi kennel site on **https://DOMAIN_SUB/** (photos + pages). Real subscription links `https://DOMAIN_SUB/shortUuid` still open Remnawave. Default **on** after install/`repair`. CLI: `sub-stub on|off|status|refresh`. Disable: `--no-sub-stub`.

### 34. User cabinet

Personal cabinet at **https://DOMAIN_PANEL/lk/**: register/sign in with email+password, Telegram, VK or Yandex; browse plans; buy or start a trial; get the subscription URL; device setup for Android, iOS, TV and PC. Material + Web 3.0 UI. Admin at `/lk/admin` edits menu tabs, plans, copy and OAuth. **No payment-gateway SDKs** — mock checkout or manual mark-paid. Local test without Remnawave:

```bash
bash remnawave-cabinet-test.sh
```

CLI: `cabinet on|off|status|url`. Disable: `--no-cabinet`.

### 0. Exit

Leaves the menu (`0`, `q` or `Q`). Nothing is uninstalled.

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

CLI: `status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `urls`, `health`, `users`, `nodes`, `telegram`, `backup-remote`, `certs`, `firewall`, `admin-login`, `core-update`, `stealth`, `addon …`, `node-transports …`, `add-node`, `check-update`, `self-update`, `--version`.

---

## Documentation

| | English | Русский |
| --- | --- | --- |
| Full guide | [docs/GUIDE.en.md](docs/GUIDE.en.md) | [docs/GUIDE.ru.md](docs/GUIDE.ru.md) |
| Menu (every item) | [docs/MENU.en.md](docs/MENU.en.md) | [docs/MENU.ru.md](docs/MENU.ru.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) | [CHANGELOG.ru.md](CHANGELOG.ru.md) |
| Security | [SECURITY.md](SECURITY.md) | [SECURITY.ru.md](SECURITY.ru.md) |
| Install notes | [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md) | same |
| License | [LICENSE](LICENSE) (MIT) | same |
| Checksums | [SHA256SUMS](SHA256SUMS) | same |
| Credits | [CREDITS.md](CREDITS.md) | same |
| Releases | [GitHub Latest](https://github.com/booarkz-cpu/remnawave-manager/releases/latest) | same |

---

## License

**MIT.** Copyright (c) 2026 Корги Люси (Corgi Lusi). Full text: [LICENSE](LICENSE).

You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this installer, provided the copyright notice and permission notice stay in all copies.

This license covers **this repository** (`remnawave-manager.sh` and its docs). It matches the MIT licenses of [DigneZzZ/remnawave-scripts](https://github.com/DigneZzZ/remnawave-scripts) and [eGamesAPI/remnawave-reverse-proxy](https://github.com/eGamesAPI/remnawave-reverse-proxy). Menu **24** downloads those authors’ original files into `/opt/remnawave-addons`; those copies stay under **their** terms. Rezzosoft’s public tree has no SPDX license — we do not relicense it; we credit the author and keep the converter as an optional link.

There is no warranty. Do not publish secrets from `credentials.txt`. See [SECURITY.md](SECURITY.md) and [SECURITY.ru.md](SECURITY.ru.md).
