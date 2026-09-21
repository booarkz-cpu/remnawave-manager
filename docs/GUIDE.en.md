# Remnawave Manager — English guide

[English](GUIDE.en.md) · [Русский](GUIDE.ru.md) · [README](../README.md)

Installer and day-to-day manager for [Remnawave](https://docs.rw) on Debian/Ubuntu. Author: **Corgi Lusi (Корги Люси)**. Current script version: **1.5.4**.

This page is the full instruction. The GitHub README describes **every menu item** in English and Russian. Historical per-release notes: [INSTALLATION_RU.md](INSTALLATION_RU.md). Bilingual changelog: [CHANGELOG.md](../CHANGELOG.md) (English) · [CHANGELOG.ru.md](../CHANGELOG.ru.md) (Русский). Security: [SECURITY.md](../SECURITY.md) · [SECURITY.ru.md](../SECURITY.ru.md). License: [MIT](../LICENSE).

Two different “updates” exist. Do not mix them:

| What | Command / menu | What changes |
| --- | --- | --- |
| **This script** (`remnawave-manager.sh`) | `check-update`, `self-update`, menu **26** | The installer file on disk |
| **Remnawave** (panel, node, subscription images) | `update`, menu **14** | Docker images; panel data stays |

---

## Contents

1. [What the script does](#1-what-the-script-does)
2. [Requirements](#2-requirements)
3. [Download and verify](#3-download-and-verify)
4. [First launch](#4-first-launch)
5. [Install: one VPS](#5-install-one-vps)
6. [Install: panel and node on two servers](#6-install-panel-and-node-on-two-servers)
7. [After install](#7-after-install)
8. [Menu](#8-menu) — full catalog: [MENU.en.md](MENU.en.md)
9. [Transports (Reality, gRPC, xHTTP, Hysteria2)](#9-transports-reality-grpc-xhttp-hysteria2)
10. [How to update this script to Latest](#10-how-to-update-this-script-to-latest)
11. [How to update Remnawave images](#11-how-to-update-remnawave-images)
12. [Repair, 502, doctor](#12-repair-502-doctor)
13. [Backup and restore](#13-backup-and-restore)
14. [CLI reference](#14-cli-reference)
15. [Files on disk](#15-files-on-disk)
16. [Add-ons and credits](#16-add-ons-and-credits)
17. [Troubleshooting](#17-troubleshooting)
18. [What not to do](#18-what-not-to-do)

---

## 1. What the script does

It installs nginx (SNI + HTTPS), Docker Compose stacks, Let’s Encrypt certificates, UFW, and a Corgi SelfSteal site for Reality. Then it talks to the Remnawave **API** and creates:

- a config profile per node named **CorgiLusi** / `CorgiLusi-…`
- inbounds for the transports you chose
- node cards, hosts (uTLS fingerprint **firefox** where Reality needs one)
- internal squad **CorgiLusi**
- user **CorgiLusi** and a subscription URL

**Default-Profile** (and leftover AUTO / Default squads) are removed after bind. You do not edit inbounds in the panel UI and you do not need the Rezzosoft converter to bind.

Bundled behaviour (original authorship kept — [CREDITS.md](../CREDITS.md)):

- Rezzosoft KVN — Hysteria2 / gRPC / xHTTP on the node
- eGamesAPI — split panel/node, stealth login, SelfSteal
- DigneZzZ — CLI, backups, Xray core, WARP/Tor, NetBird

---

## 2. Requirements

- Debian or Ubuntu VPS (tested on Ubuntu 24.04)
- Public IPv4
- DNS **A** records:
  - panel domain → panel VPS
  - subscription domain → panel VPS
  - Reality SNI domain → the VPS that runs the node (same machine on a single-VPS install)
- Ports 80/tcp and 443/tcp free for nginx / ACME
- Do not paste PowerShell onto the Linux VPS

Recommended: three hostnames on one zone, for example `pst.example.com`, `sb.example.com`, `blog.example.com`.

---

## 3. Download and verify

Always take **GitHub Latest**, not `raw.githubusercontent.com/main`.

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

The two hashes must match. Latest release: <https://github.com/booarkz-cpu/remnawave-manager/releases/latest>

Pinned copy (example for 1.5.4):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.4/remnawave-manager.sh \
  -o remnawave-manager.sh
sha256sum remnawave-manager.sh
# 1.5.4: 4a6200b2118c8df6f3a6f38f5efd48a0b2afa9c7358538fb7b5338391b9f7afa
```

See [SHA256SUMS](../SHA256SUMS) in the repo for every versioned file.

---

## 4. First launch

```bash
bash remnawave-manager.sh
```

Do **not** type `sudo` in front. If you are not root, the script re-runs through sudo by itself. `--help` stays unprivileged.

No arguments: **language first** (English / Русский; Enter keeps the current `RW_LANG`), then the numbered menu.

Skip the picker: `--lang en|ru` (stored in `/opt/remnawave/manager.env`, or the edge env on a node-only VPS). Later in the session: menu item **22**.

```bash
bash remnawave-manager.sh --lang en
bash remnawave-manager.sh --lang ru
```

Later: menu item **22**. Help:

```bash
bash remnawave-manager.sh --help
```

Optional: copy the script to `PATH` (menu **19**):

```bash
bash remnawave-manager.sh install-script
# then: remnawave-manager
```

From **1.3.0** the menu checks GitHub Latest (at most once every 6 hours). If a newer script exists, it asks whether to install it. Disable: `--no-update-check`.

---

## 5. Install: one VPS

Menu **1** or:

```bash
bash remnawave-manager.sh --lang en install single --yes \
  DOMAIN_PANEL=pst.example.com \
  DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com
```

Dry-run (no install):

```bash
bash remnawave-manager.sh install single --dry-run --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com
```

`install` runs `apt-get full-upgrade`. The VPS is not rebooted automatically. If `/var/run/reboot-required` appears, reboot after the installer finishes.

The panel runs in Docker. The node uses `network_mode: host`. The address written on the Node card is the `remnawave-network` gateway, **not** `127.0.0.1`.

If Remnawave is already on this VPS, items 1–3 offer **repair**, **re-bind**, or a full reinstall instead of running `apt full-upgrade` again.

---

## 6. Install: panel and node on two servers

**Panel first** (menu **2**). `EDGE_ADDRESS` is the public IP of the node VPS so the Node card exists immediately:

```bash
bash remnawave-manager.sh --lang en install panel --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com \
  EDGE_ADDRESS=203.0.113.20
```

Copy **Node secret** from `/opt/remnawave/credentials.txt` on the panel (never commit or paste it into GitHub).

**Node** on the other VPS (menu **3**; `install node` = `install edge`):

```bash
bash remnawave-manager.sh --lang en install node --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='secret_from_credentials.txt'
```

Point the Reality hostname at the **node** IP. Point panel and subscription hostnames at the **panel** IP.

If you installed the panel without `EDGE_ADDRESS`, run menu **4** / `protocols` on the panel after the node is up.

---

## 7. After install

Menu **23** prints public URLs without passwords.

| Item | Where |
| --- | --- |
| Panel | `https://DOMAIN_PANEL` |
| Subscription page | `https://DOMAIN_SUB` |
| Reality SNI (Corgi site) | `https://DOMAIN_REALITY` |
| Admin / API token / node secret | `/opt/remnawave/credentials.txt` |
| Manager flags | `/opt/remnawave/manager.env` (node-only: `/opt/remnawave-edge/manager.env`) |
| Install log | `/var/log/remnawave-manager.log` |

Delete `credentials.txt` after you have stored the secrets somewhere safe.

The panel backend requires reverse-proxy headers (`X-Forwarded-For` and `X-Forwarded-Proto: https`). The installer writes those into nginx. Do not bypass nginx and call `:3000` from the internet.

---

## 8. Menu

Numbers **1–27** stay; **28–32** were added in 1.5.0. **Full functionality of every item:** [MENU.en.md](MENU.en.md) · [Русский](MENU.ru.md) · also in the GitHub [README](../README.md#menu).

| # | Function | What it does |
| --- | --- | --- |
| 1 | Full install | Panel + node on one VPS |
| 2 | Panel only | Panel + subscription HTTPS |
| 3 | Node only | remnanode + Reality SNI |
| 4 | Auto-bind protocols | Rebuild CorgiLusi profiles, squad, hosts; drop Default-Profile |
| 5 | Status | Containers, nginx, fail2ban, timers |
| 6 | Doctor | API, `:3010`, public HTTPS, certs, UDP/TCP listen, node Connected, UFW |
| 7 | Repair | Fix nginx headers and subscription 502; keep Docker/DB |
| 8 | Logs | Follow remnawave / remnanode / subscription-page |
| 9 | Up | `docker compose up` for every stack |
| 10 | Down | `docker compose down` (data kept) |
| 11 | Restart | Restart every Remnawave compose stack |
| 12 | Backup | Archive under `/var/backups/remnawave` |
| 13 | Restore | Restore a `.tgz` or `.age` archive |
| 14 | Update | Backup + pull **Remnawave images** (not this script) |
| 15 | Uninstall | Remove services and nginx vhosts; backups stay |
| 16 | Xray core | Custom binary or restore the image builtin |
| 17 | Add-ons | DigneZzZ CLI, SelfSteal, WARP/Tor, NetBird, eGames |
| 18 | Stealth login | Hide `/auth/login` behind a secret |
| 19 | Install CLI | Copy to `/usr/local/bin/remnawave-manager` |
| 20 | Converter | Optional Rezzosoft JSON helper — not required to bind |
| 21 | Credits / help | Authorship and CLI help |
| 22 | Language | English or Русский |
| 23 | URLs | Panel / sub / SNI / CorgiLusi; type SHOW for admin login once |
| 24 | Author updates | Refresh upstream modules (this script: item **26**) |
| 25 | Node transports | Add or remove xHTTP, gRPC, Hysteria2; panel then prints apply-on-node |
| 26 | This script | Check / install GitHub Latest of this installer |
| 27 | Add a node | Register another node via API — no OS upgrade, no menu 1 |
| 28 | Users | List / create / enable / disable / subscription URL |
| 29 | Node control | Disable, enable, restart one node, change address |
| 30 | Alerts and remote backup | Telegram test; rclone+age off-VPS |
| 31 | Certificates | Days left, renew now, `/dev/shm` on the node |
| 32 | Firewall | ADMIN_IP allowlist, rebuild UFW |
| 0 | Exit | — |

---

## 9. Transports (Reality, gRPC, xHTTP, Hysteria2)

Default at install: **all four**.

| Transport | Port | Notes |
| --- | --- | --- |
| VLESS Reality TCP | 443 | SNI = Reality domain; host fingerprint firefox |
| Hysteria2 | UDP/443 (+ sing-box UDP/8443) | No uTLS fingerprint |
| VLESS gRPC Reality | TCP/8443 | path `/grpc`, fingerprint firefox |
| VLESS xHTTP Reality | TCP/4443 | path `/xhttp`, fingerprint firefox |

Install-time flags: `--all-protocols` (default), `--reality-only`, `--hysteria2`, `--grpc`, `--xhttp`.

**Full re-bind** of every profile (menu **4** / `protocols` / `bind`): use after install or when you want CorgiLusi profiles rebuilt. If you do not pass a protocol flag, this command turns **all** transports on.

**Add or remove extras on a node that is already up** — including a node on another VPS — is a **separate** item (**25**). Adding one transport does not reset the others. Pick a node (number, UUID, or `0` = all). After a node, `[0]` returns to that list; `q` leaves for the main menu. On a **panel-only** VPS, 1–8 print the copy-paste for the node: `bash remnawave-manager.sh node-transports apply`.

On the **panel**:

```bash
bash remnawave-manager.sh node-transports add grpc
bash remnawave-manager.sh node-transports add xhttp
bash remnawave-manager.sh node-transports add hysteria2
bash remnawave-manager.sh node-transports add all
bash remnawave-manager.sh node-transports remove grpc
bash remnawave-manager.sh node-transports remove xhttp
bash remnawave-manager.sh node-transports remove hysteria2
bash remnawave-manager.sh node-transports reality-only
```

On the **node** VPS (UFW, `/dev/shm` certs, sing-box Hysteria2):

```bash
bash remnawave-manager.sh node-transports apply
```

---

## 10. How to update this script to Latest

This section updates **only** `remnawave-manager.sh` (and `/usr/local/bin/remnawave-manager` if you installed the CLI). It does **not** pull Docker images and does **not** wipe the panel database.

First, the version in the help header: `bash remnawave-manager.sh --help`.

### Method A — 1.1.0 or 1.2.0 (`check-update` prints help)

Those builds **do not** have `check-update`. An unknown command prints the full `--help` — that is not a network error. 1.1.0 already has `self-update`:

```bash
bash remnawave-manager.sh self-update
```

After the replace, the header should show `1.4.0` or newer. Then `check-update` and the menu auto-check work.

### Method B — already 1.3.0 or newer

1. Open the menu: `bash remnawave-manager.sh`
2. If GitHub Latest is newer, answer **Y**.
3. Or:

```bash
bash remnawave-manager.sh check-update
bash remnawave-manager.sh check-update --apply
```

Equivalent: menu **26**, or `self-update` again. From 1.4.0 an unknown command prints a short hint instead of the full help.

Skip the automatic GitHub query:

```bash
bash remnawave-manager.sh --no-update-check
```

The last check time is stored as `LAST_UPDATE_CHECK_AT` / `LAST_REMOTE_VERSION` in `manager.env` (6 hour cache). Menu **26** → **1** checks without downloading.

### Method C — no `self-update` (1.0.0 / 25.2.x) or GitHub unreachable

Download Latest by hand and verify the hash:

```bash
cd ~
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

If the hashes differ, **do not run** the file. If they match:

```bash
grep VERSION= remnawave-manager.sh | head -1
bash remnawave-manager.sh --lang en
```

If you previously used menu **19**, refresh the CLI copy from the new file:

```bash
bash remnawave-manager.sh install-script
```

Run this on **every** VPS that has the manager: panel and node.

### After the script file is updated

You usually **do not** reinstall Remnawave.

| Goal | Next step |
| --- | --- |
| Subscription or panel HTTP 502 | menu **7** / `repair` |
| New bind / CorgiLusi / firefox fingerprint | menu **4** / `protocols` on the **panel** |
| Add/remove gRPC, xHTTP, Hysteria2 | menu **25** / `node-transports` (panel, then `apply` on the node) |
| New Remnawave container images | menu **14** / `update` (this is not a script update) |

### Wrong ways to “update the script”

- `raw.githubusercontent.com/.../main/remnawave-manager.sh` — not a release, may be incomplete
- Running menu **1** again “to get a new script” — that is a reinstall, not a script update
- Running menu **14** and expecting this GitHub file to change — **14** only pulls Docker images
- PowerShell `Invoke-WebRequest` on the Linux VPS
- Prefixing `sudo` (the script elevates itself)

---

## 11. How to update Remnawave images

Menu **14** or:

```bash
bash remnawave-manager.sh update
```

Order: backup → pull panel → node → subscription → Hysteria2 → check panel API → reload nginx. Keep this separate from [section 10](#10-how-to-update-this-script-to-latest).

---

## 12. Repair, 502, doctor

If the panel or the subscription page returns **502**, nginx is probably missing `X-Forwarded-For` / `X-Forwarded-Proto: https`, or `remnawave-subscription-page` is down.

```bash
bash remnawave-manager.sh repair   # menu 7
bash remnawave-manager.sh doctor
bash remnawave-manager.sh urls
```

Repair rewrites nginx and the subscription compose **without** dropping PostgreSQL. `repair` restores domains from `.env`, `credentials.txt`, nginx and Let’s Encrypt if `manager.env` only has the language.

Logs:

```bash
tail -100 /var/log/remnawave-manager.log
bash remnawave-manager.sh logs remnawave
bash remnawave-manager.sh logs remnawave-subscription-page
bash remnawave-manager.sh logs remnanode
```

---

## 13. Backup and restore

```bash
bash remnawave-manager.sh backup
bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

Age-encrypted archives need `/opt/remnawave/backup-age.key`. Uninstall (menu **15**) removes services and vhosts; backup files stay.

---

## 14. CLI reference

```text
bash remnawave-manager.sh                         # menu
bash remnawave-manager.sh --lang en|ru
bash remnawave-manager.sh --help
bash remnawave-manager.sh --version
bash remnawave-manager.sh --no-update-check

bash remnawave-manager.sh install single|panel|node [--yes] [--dry-run]
bash remnawave-manager.sh protocols | bind
bash remnawave-manager.sh add-node
bash remnawave-manager.sh node-transports add|remove grpc|xhttp|hysteria2|all [uuid]
bash remnawave-manager.sh node-transports apply | reality-only

bash remnawave-manager.sh check-update [--apply]
bash remnawave-manager.sh self-update
bash remnawave-manager.sh community-update

bash remnawave-manager.sh status | doctor | repair | urls
bash remnawave-manager.sh users list
bash remnawave-manager.sh users create NAME [DAYS|YYYY-MM-DD] [GB|512M|10G] [DEVICES]
bash remnawave-manager.sh users enable|disable|sub UUID_OR_NAME
bash remnawave-manager.sh nodes list|disable|enable|restart|address
bash remnawave-manager.sh telegram enable|disable|test
bash remnawave-manager.sh backup-remote [rclone:path]
bash remnawave-manager.sh certs [renew|force]
bash remnawave-manager.sh firewall [IPv4]
bash remnawave-manager.sh admin-login SHOW
bash remnawave-manager.sh backup | restore FILE | update
bash remnawave-manager.sh up | down | restart | logs [container]
bash remnawave-manager.sh stealth | install-script
bash remnawave-manager.sh addon remnawave|remnanode|selfsteal|wtm|netbird|egames
```

`--yes` needs domains/email (and node secret in node mode) on the command line.

---

## 15. Files on disk

| Path | Role |
| --- | --- |
| `/opt/remnawave/` | Panel compose, `.env`, `manager.env` |
| `/opt/remnawave/subscription/` | Subscription page |
| `/opt/remnawave/node/` | Node on a single VPS |
| `/opt/remnawave-edge/` | Node-only VPS |
| `/opt/remnawave/hysteria2/` | sing-box Hysteria2 |
| `/opt/remnawave/credentials.txt` | Admin, tokens, node secret |
| `/opt/remnawave-addons/` | Downloaded upstream modules (menu 24) |
| `/var/backups/remnawave/` | Backups |
| `/usr/local/sbin/remnawave-health-notify.sh` | Telegram from the 5-minute healthcheck (menu **30**) |
| `/usr/local/bin/remnawave-manager` | Optional CLI copy |

Never publish API tokens, `SECRET_KEY`, PostgreSQL password, or `credentials.txt`. See [SECURITY.md](../SECURITY.md) and [SECURITY.ru.md](../SECURITY.ru.md).

---

## 16. Add-ons and credits

Menu **24** / `community-update` downloads the **original** Rezzosoft / eGames / DigneZzZ scripts into `/opt/remnawave-addons` and records authors in `AUTHORS.txt`. We do not claim that code as ours.

Optional converter (not required to bind): <https://rezzosoft.ru/converter.html>

---

## 17. Troubleshooting

| Symptom | What to do |
| --- | --- |
| Panel or sub **502** | `repair`; check `docker ps` for `remnawave-subscription-page` |
| `repair` asks for DOMAIN_* | Enter panel / sub / Reality hostnames; 1.3.x also hydrates them from disk |
| Node not Connected | Panel IP in UFW for 2222; `SECRET_KEY` matches `credentials.txt`; Reality DNS → node |
| Extra protocol does not work | Item **25** on the panel, then `node-transports apply` on the node |
| `check-update` prints the full `1.1.0` help | Old script. Run `bash remnawave-manager.sh self-update` (from 1.4.0 unknown commands print a short hint) |
| Menu does not see a new script | menu **26**, `self-update` or `check-update --apply` (from 1.3.0); 6 hour cache |
| Hash mismatch | Delete the file; download Latest again; do not run it |
| `"-":0: bad minute` on old 25.2.2 | Update the **script** (section 10), then `protocols` — Hysteria certs use systemd, not crontab |

---

## 18. What not to do

- Do not prefix the command with `sudo`
- Do not run PowerShell on the VPS
- Do not bind inbounds by hand in the panel if the installer already did it
- Do not point the node card at `127.0.0.1` on a single VPS
- Do not treat menu **14** as an update of this GitHub script
- Do not publish `credentials.txt`

Questions about versions: [CHANGELOG.md](../CHANGELOG.md) · [CHANGELOG.ru.md](../CHANGELOG.ru.md), [releases](https://github.com/booarkz-cpu/remnawave-manager/releases).
