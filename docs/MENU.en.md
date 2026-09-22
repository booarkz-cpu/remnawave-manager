# Menu — every item in full

[English](MENU.en.md) · [Русский](MENU.ru.md) · [README](../README.md) · [Guide](GUIDE.en.md)

Open the menu with no arguments: `bash remnawave-manager.sh`. **Language is asked first** (Enter keeps the current one); item **22** switches later. Do not type `sudo`. Numbers **1–27** stay; **28–32** were added in 1.5.0; **33** is the SUB-domain Corgi stub (1.5.5); **34** is the user cabinet (1.6.0). **0** / `q` leaves.

Two updates that look similar and are not:

| Goal | Menu | CLI |
| --- | --- | --- |
| New installer file | **26** | `self-update` / `check-update --apply` |
| New Remnawave Docker images | **14** | `update` |

---

## 1. Full install

Puts **panel + node on one VPS**.

Asks for panel, subscription and Reality hostnames and an admin email, then which transports to enable (default: Reality + Hysteria2 + gRPC + xHTTP). Runs a preflight (Ubuntu/Debian, DNS, TCP 80/443 free, disk, Docker). Installs packages, `apt-get full-upgrade` (no automatic reboot), fail2ban, BBR, Docker Compose stacks, nginx SNI, Let’s Encrypt, the CorgiLusi user, one config profile per node, inbounds, hosts, the **CorgiLusi** squad, and removes **Default-Profile**. The node uses `network_mode: host`; the Node card address is the `remnawave-network` gateway, not `127.0.0.1`. Writes `/opt/remnawave/credentials.txt` and systemd timers (backup, certs, health).

If Remnawave is already on this VPS, items 1–3 offer **repair**, **re-bind**, or a full reinstall instead of running `apt full-upgrade` again.

Does **not** replace this GitHub script (that is item **26**) and does **not** pull newer panel images later (that is item **14**).

CLI: `bash remnawave-manager.sh install single`

---

## 2. Panel only

Panel + subscription HTTPS on this VPS. No remnanode here.

`EDGE_ADDRESS` (node public IP) creates the Node card immediately via API. Copy **Node secret** from `/opt/remnawave/credentials.txt` onto the other VPS and run item **3** there.

CLI: `bash remnawave-manager.sh install panel`

---

## 3. Node only

remnanode in host-network + Reality SNI on a second VPS. Needs `PANEL_IP`, Reality domain, admin email and `NODE_SECRET_KEY` from the panel `credentials.txt`. Opens UFW toward the panel (including node port 2222). Prepares ports and `/dev/shm` certs for the transports you picked.

CLI: `bash remnawave-manager.sh install node` (same as `install edge`)

---

## 4. Auto-bind protocols

**Full rebuild** of CorgiLusi: per-node config profiles, inbounds, hosts, squad. Drops Default-Profile. Reality hosts use uTLS fingerprint **firefox**. Without a protocol flag this command turns **all** transports on.

Use after a fresh install, after a script update that changes bind logic, or when the panel UI was edited by hand. This is not a surgical add/remove — that is item **25**.

CLI: `bash remnawave-manager.sh protocols` (alias: `bind`)

---

## 5. Status

Live local health: Docker containers, nginx, fail2ban, systemd timers. The menu header already shows panel API / `:3010` / remnanode dots; this item prints the long form.

CLI: `bash remnawave-manager.sh status`

---

## 6. Doctor

Diagnostics, no writes:

- this script version vs GitHub Latest
- OS, Docker, `nginx -t`
- panel API `/auth/status`
- `remnawave-subscription-page` and HTTP on `:3010`
- public HTTPS
- Let’s Encrypt days left (warns under 21 days)
- listen: TCP 80/443; UDP 443/8443 if Hysteria2; TCP 8443 if gRPC; TCP 4443 if xHTTP
- `ss` on common ports
- each node **Connected** / disconnected via API (not on a node-only VPS)
- `docker ps`, remnawave timers, UFW

CLI: `bash remnawave-manager.sh doctor`

---

## 7. Repair

Fixes **HTTP 502** on panel or subscription without wiping Docker or PostgreSQL. Rewrites nginx (`X-Forwarded-For`, `X-Forwarded-Proto: https`), subscription compose, SelfSteal. Restores `DOMAIN_*` from `.env`, `credentials.txt`, nginx and Let’s Encrypt if `manager.env` only has the language.

CLI: `bash remnawave-manager.sh repair`

---

## 8. Logs

Asks which container, then `docker compose logs -f`. Typical names: `remnawave`, `remnanode`, `remnawave-subscription-page`. Empty input follows a default.

CLI: `bash remnawave-manager.sh logs remnawave`

---

## 9. Start (up)

`docker compose up` for every Remnawave stack found: panel, node (single or edge), subscription, Hysteria2, monitoring. Does not install missing stacks.

CLI: `bash remnawave-manager.sh up`

---

## 10. Stop (down)

`docker compose down` on those stacks. **Volumes and `/opt/remnawave` stay.** Not uninstall.

CLI: `bash remnawave-manager.sh down`

---

## 11. Restart

Restarts every Remnawave compose stack (panel, node, subscription, Hysteria2). Does not pull images.

CLI: `bash remnawave-manager.sh restart`

---

## 12. Backup

Writes an archive under `/var/backups/remnawave` (compose, env, nginx snippets, credentials). Optional age encryption uses `/opt/remnawave/backup-age.key`. Does not stop the panel first unless the backup helper does.

CLI: `bash remnawave-manager.sh backup`

---

## 13. Restore

Asks for a `.tgz` or `.age` path and restores it. Age archives need the private key on disk. After a failed item **14** the script may restore the latest snapshot by itself.

CLI: `bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz`

---

## 14. Update (Remnawave images)

**Docker images only**, not this `.sh` file.

Order: backup → pull panel → node → subscription → Hysteria2 → check panel API → reload nginx. If a step fails, it tries to restore the last backup.

CLI: `bash remnawave-manager.sh update`

---

## 15. Uninstall

Type `DELETE` to confirm. Stops compose stacks, disables remnawave systemd timers, removes nginx vhosts and helper scripts. **Backup files in `/var/backups/remnawave` stay.** Does not `rm -rf /opt/remnawave` by itself.

CLI: `bash remnawave-manager.sh uninstall` (with `--yes` skips the `DELETE` prompt)

---

## 16. Xray core

Replace the node Xray binary with an official/custom build, or restore the image builtin. Applies to `/opt/remnawave/node` (or the edge path).

CLI: `bash remnawave-manager.sh core-update`

---

## 17. Add-ons

Runs **upstream** helpers (authorship kept). Sub-menu:

| Key | What |
| --- | --- |
| **a** | DigneZzZ remnawave CLI — panel helper |
| **b** | DigneZzZ remnanode CLI — node helper |
| **c** | SelfSteal templates |
| **d** | WARP / Tor (`wtm`) |
| **e** | NetBird |
| **f** | eGames reverse-proxy installer |

These are optional extras. Binding inbounds still happens through this manager (items **4** / **25**), not through the converter.

CLI: `bash remnawave-manager.sh addon remnawave|remnanode|selfsteal|wtm|netbird|egames`

---

## 18. Stealth login

eGames-style gate: `/auth/login` returns 404 until the secret query or cookie is present, then sets an HttpOnly cookie. Prints `https://PANEL/auth/login?KEY=KEY`. Needs the panel nginx vhost already installed.

CLI: `bash remnawave-manager.sh stealth`

---

## 19. Install CLI

Copies this file to `/usr/local/bin/remnawave-manager` so you can type `remnawave-manager` without a path. After a manual `curl` of a new script, run this again (or `install-script`) so PATH matches GitHub Latest.

CLI: `bash remnawave-manager.sh install-script`

---

## 20. Converter

Opens/prints the optional Rezzosoft JSON helper: <https://rezzosoft.ru/converter.html>. **Not required** to install or bind. Profiles, hosts and the squad are created via the Remnawave API.

---

## 21. Credits / help

Prints Corgi Lusi authorship, Rezzosoft / eGames / DigneZzZ credits, and the full CLI `--help`. Same as `bash remnawave-manager.sh --help` plus the in-menu credits block.

---

## 22. Language

Asked **at every menu start** (before items 1–32). **English** or **Русский**. Enter keeps the current language. Saved as `RW_LANG` in `/opt/remnawave/manager.env` (edge env on a node-only VPS). This item switches again without leaving the session.

Skip the startup picker: `bash remnawave-manager.sh --lang en|ru`

---

## 23. URLs

Panel, subscription, Reality SNI and the CorgiLusi user subscription link. **No passwords, JWT or node secret** until you type **SHOW**. Then the panel login is printed **once** on the terminal and is **not** written to `/var/log/remnawave-manager.log`. Anything other than SHOW cancels.

CLI: `bash remnawave-manager.sh urls` · public check: `health` · `bash remnawave-manager.sh admin-login SHOW`

---

## 24. Author updates

Downloads the **original** Rezzosoft / eGames / DigneZzZ scripts into `/opt/remnawave-addons` and writes `AUTHORS.txt`. This manager does not claim that code.

Sub-menu:

1. Refresh all author modules (download only)
2. Update **this** Corgi Lusi script from GitHub Latest (same as **26** → install)
3. Check GitHub Latest without downloading
0. Back

CLI: `bash remnawave-manager.sh community-update`

---

## 25. Node transports

Add or remove **xHTTP, gRPC, Hysteria2** on a node that is already installed (including a node on another VPS). Adding one transport does not turn the others back on. Reality stays.

Flow:

1. Pick a node: number, pasted UUID, or **0** = all. **q** = main menu.
2. Transports for that node:
   - **[1]** Add Hysteria2 (UDP/443 + sing-box UDP/8443)
   - **[2]** Add gRPC (VLESS Reality TCP/8443)
   - **[3]** Add xHTTP (VLESS Reality TCP/4443)
   - **[4]** Add all three (keep Reality)
   - **[5]** Remove Hysteria2
   - **[6]** Remove gRPC
   - **[7]** Remove xHTTP
   - **[8]** Remove all three (Reality only)
   - **[9]** Apply on **this** server (node: UFW, `/dev/shm` certs, Hysteria2 stack)
   - **[0]** Back to the **node list**
   - **[q]** Main menu

On the **panel**, 1–8 update profile, inbounds, hosts and squad via API (extra hosts are pruned), then print a **checklist**: node UUID (or “all”) and the exact command to run on the node VPS — `bash remnawave-manager.sh node-transports apply`. On the **node** VPS run **[9]** or that command. Split install: panel first, then apply on the node.

CLI:

```bash
bash remnawave-manager.sh node-transports add grpc|xhttp|hysteria2|all [uuid]
bash remnawave-manager.sh node-transports remove grpc|xhttp|hysteria2|all [uuid]
bash remnawave-manager.sh node-transports reality-only
bash remnawave-manager.sh node-transports apply
```

---

## 26. This script

GitHub **Latest of this installer**, not Docker images.

1. Check Latest again (no download)
2. Install Latest now (`self-update`: download, `bash -n`, replace this file and `/usr/local/bin/remnawave-manager` if present, restart)
0. Back

From 1.3.0 the main menu also checks Latest at most every 6 hours (from 1.4.3 the cache does not hide a newer tag). Skip: `--no-update-check`.

CLI: `bash remnawave-manager.sh check-update` · `check-update --apply` · `self-update` · `--version`

---

## 27. Add a node

Registers **another** node on an already-running **panel** via API: address, name, profile, bind, hosts, squad. **No** `apt full-upgrade`, **no** menu **1**. Then on the new VPS run item **3** / `install node` with the Node secret from `credentials.txt`.

Must be run on the panel (not on a node-only VPS).

CLI: `bash remnawave-manager.sh add-node`

---

## 28. Users

**Panel VPS only.** VPN users via API — not the panel admin password.

1. List (username, status, UUID)
2. Create — username (3–32 `A–Za-z0-9._-`, starts with a letter), then:
   - subscription **expiry**: days `1–36500` or `YYYY-MM-DD` (default **365** days)
   - **traffic** cap: `0` = unlimited, bare integer = GiB, or `512M` / `10G` / `1T`
   - **device** (HWID) limit: `0` = no cap, else `1–1000`
   Same **CorgiLusi** squad. API fields: `expireAt`, `trafficLimitBytes`, `trafficLimitStrategy=NO_RESET`, optional `hwidDeviceLimit`.
3. Enable
4. Disable
5. Show **subscription URL** (from API `subscriptionUrl`, or `https://SUB_DOMAIN/shortUuid`)
0. Back · **q** main menu

CLI:

```bash
bash remnawave-manager.sh users list
bash remnawave-manager.sh users create Alice 365 0 0
bash remnawave-manager.sh users create Alice 30 10G 3
bash remnawave-manager.sh users create Alice 2027-12-31 512M 2
bash remnawave-manager.sh users enable UUID_OR_NAME
bash remnawave-manager.sh users disable UUID_OR_NAME
bash remnawave-manager.sh users sub UUID_OR_NAME
```

Non-interactive defaults: `USER_EXPIRE_DAYS`, `USER_TRAFFIC_GB`, `USER_DEVICE_LIMIT`.

---

## 29. Node control

**Panel VPS only.** Act on **one** node (pick like item 25). Restart may use `0` / `all`.

1. List (name, address, Connected/disabled, UUID)
2. Restart (`forceRestart` when the API needs it)
3. Disable
4. Enable
5. Change address (IPv4 or hostname) — `PATCH /nodes/` with `uuid` in the JSON body
0. Back

CLI:

```bash
bash remnawave-manager.sh nodes list
bash remnawave-manager.sh nodes restart [UUID|all]
bash remnawave-manager.sh nodes disable UUID
bash remnawave-manager.sh nodes enable UUID
bash remnawave-manager.sh nodes address UUID 203.0.113.20
```

---

## 30. Alerts and remote backup

Telegram and off-VPS backup from one menu. The bot **token is not printed** in the installer log.

1. Enable Telegram (bot token + chat id, optional thread) — writes `TELEGRAM_*` to `manager.env`, installs `/usr/local/sbin/remnawave-health-notify.sh`, hooks the 5-minute healthcheck
2. Send a test message
3. Disable alerts (`TELEGRAM_ALERTS=0`; token stays on disk)
4. Set rclone destination and enable the daily **02:00** timer (`age` encrypt, then `rclone copy`)
5. Run encrypted remote backup **now**
6. Disable the remote-backup timer
0. Back

Healthcheck (at most once an hour per event): panel API down, Let’s Encrypt **< 21 days**, node not Connected.

CLI: `telegram enable|disable|test` · `backup-remote [rclone:path]` (no path = run now)

---

## 31. Certificates

1. Days left for panel / sub / Reality
2. `certbot renew` now, then nginx reload
3. Force-renew those three names (`--force-renewal`)
4. Copy certs into `/dev/shm` on **this** server (Hysteria2)
0. Back

The **menu header** shows the nearest expiry (yellow under 21 days).

CLI: `certs` · `certs renew` · `certs force`

---

## 32. Firewall

1. `ufw status verbose`
2. Set **ADMIN_IP** (IPv4) and rebuild — SSH only from that address
3. Clear ADMIN_IP and rebuild — SSH from any IPv4 on the SSH port
4. Rebuild UFW with current install flags (80/443, transports, node 2222)
0. Back

CLI: `firewall` · `firewall 203.0.113.10`

---

## 33. Subscription stub

**Panel / single VPS.** A Corgi Lusi kennel site (photos, about, breed, gallery, contacts) is served at **https://DOMAIN_SUB/**. Visiting the domain looks like a normal kennel website. A user subscription URL `https://DOMAIN_SUB/<shortUuid>` is still proxied to `remnawave-subscription-page` on `:3010`.

Enabled by default on install and `repair`. Menu:

1. Status
2. Enable
3. Disable (SUB root proxies to subscription-page again)
4. Refresh HTML/CSS and re-download photos
0. Back

Photos come from `assets/sub-stub-photos.tgz` next to the script, or GitHub Latest / jsDelivr. If the archive is missing, SVG illustrations are used. Enable and refresh both go through `sub_stub_apply`: a node-only VPS prints that there is no SUB domain and does not rewrite panel nginx.

CLI:

```bash
bash remnawave-manager.sh sub-stub status
bash remnawave-manager.sh sub-stub on
bash remnawave-manager.sh sub-stub off
bash remnawave-manager.sh sub-stub refresh
```

Install without the stub: `--no-sub-stub`.

---

## 34. User cabinet

**Panel / single VPS.** A Material Design + Web 3.0 personal cabinet at **https://DOMAIN_PANEL/lk/**. Users register or sign in with email and password, Telegram, VK or Yandex Mail. They browse plans, start a trial, buy a plan (mock checkout — **no payment-gateway SDKs**), receive a Remnawave subscription URL, and read setup instructions for Android, iOS, TV and PC.

Admin UI: **https://DOMAIN_PANEL/lk/admin** (same password as the panel admin unless `CABINET_ADMIN_PASSWORD` is set). From there you edit cabinet menu tabs, add pages, tariffs, device instructions and OAuth client ids. Secrets are not returned by the settings API.

Local test without Remnawave, Docker, or payment gateways:

```bash
bash remnawave-cabinet-test.sh
# http://127.0.0.1:43291/        user cabinet
# http://127.0.0.1:43291/admin   admin (password corgi-test)
```

```bash
bash remnawave-manager.sh cabinet status
bash remnawave-manager.sh cabinet on
bash remnawave-manager.sh cabinet off
```

Install without the cabinet: `--no-cabinet`.

---

## 0. Exit

Leaves the menu (`0`, `q` or `Q`). Nothing is uninstalled.

---

## License

This installer is **MIT** — [LICENSE](../LICENSE). Files that item **24** downloads into `/opt/remnawave-addons` stay under their authors’ licenses. See [CREDITS.md](../CREDITS.md).
