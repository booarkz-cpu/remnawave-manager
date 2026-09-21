# Menu — every item in full

[English](MENU.en.md) · [Русский](MENU.ru.md) · [README](../README.md) · [Guide](GUIDE.en.md)

Open the menu with no arguments: `bash remnawave-manager.sh`. Do not type `sudo`. Numbers **1–27** are fixed; **0** / `q` leaves.

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

**English** or **Русский**. Saved as `RW_LANG` in `/opt/remnawave/manager.env` (edge env on a node-only VPS).

CLI: `bash remnawave-manager.sh --lang en|ru`

---

## 23. URLs

Panel, subscription, Reality SNI and the CorgiLusi user subscription link. **No passwords, JWT or node secret.**

CLI: `bash remnawave-manager.sh urls` · public check: `health`

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

On the **panel**, 1–8 update profile, inbounds, hosts and squad via API (extra hosts are pruned). On the **node** VPS run **[9]** or `node-transports apply`. Split install: panel first, then apply on the node.

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

## 0. Exit

Leaves the menu (`0`, `q` or `Q`). Nothing is uninstalled.

---

## License

This installer is **MIT** — [LICENSE](../LICENSE). Files that item **24** downloads into `/opt/remnawave-addons` stay under their authors’ licenses. See [CREDITS.md](../CREDITS.md).
