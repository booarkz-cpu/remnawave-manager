# Changelog

English journal. Русский: [CHANGELOG.ru.md](CHANGELOG.ru.md).

## 1.5.4

Creating a user from the menu (item **28**) and CLI now sets **subscription expiry**, a **traffic cap**, and a **device (HWID) limit**. API fields: `expireAt`, `trafficLimitBytes`, `trafficLimitStrategy=NO_RESET`, and `hwidDeviceLimit` when the limit is greater than 0. Defaults: 365 days, unlimited traffic, no HWID cap. CLI: `users create NAME [DAYS|YYYY-MM-DD] [GB|512M|10G] [DEVICES]`.

Opening the menu asks for **language first** (Enter keeps the current one), not only via item 22. `--lang` and `--yes` skip the picker.

Audit: CLI `KEY=VALUE` no longer overwrites `PATH` / `IFS` / `LD_PRELOAD` (same denylist as `manager.env`). `users_cli` forwards every argument after `create`. Repeat API token names no longer pipe `date | tail` (less SIGPIPE). User/node picks use `10#`. A broken users-list JSON no longer aborts the menu.

SHA256:
`4a6200b2118c8df6f3a6f38f5efd48a0b2afa9c7358538fb7b5338391b9f7afa`

## 1.5.3

Second audit pass: a menu item that `die`s no longer exits the whole script (`menu_call` in a subshell; `self-update` still not in a subshell because of `exec`). A dropped `curl` to the API yields HTTP 000 instead of ERR. Typing `08` in the user/node picker no longer crashes on octal arithmetic. Flags from `manager.env` are coerced to 0/1; `DRY_RUN` / `AUTO_YES` / `PATH` are not loaded from env.

SHA256:
`ebfe8913476c0f04a5e13694f30b0bfbb7fa4cd0b81d5d1b9e7018906e9add98`

## 1.5.2

Full `set -e` / ERR audit: item **13** calls `restore` again (the call was dropped in 1.5.1). `ask` no longer spins forever on Ctrl+D. `manager.env` does not overwrite `VERSION`/`PATH`. `upsert` keeps `\` in passwords. Restore does not `cd` into the panel directory and does not hang a RETURN trap on nested functions. Items 27–32 on a node-only VPS return to the menu instead of aborting the script. `show_result` still does not print the password.

SHA256:
`65a1a8ef96d427863c0fdad5fc765dee634f18562b34723a5e6a768acb9bc0ba`

## 1.5.1

Item **26** → **1** no longer aborts the script (`set -e` + exit code 1 from the Latest check). The Latest tag is taken from the first GitHub redirect (`/releases/tag/v…`), not from the CDN host `release-assets.githubusercontent.com` (that URL has no version — 1.5.0 reported “network”). Fallbacks: atom and jsDelivr. `self-update` downloads from GitHub, then jsDelivr. The 6-hour cache applies again when the script is already current; live check: item 26 / `check-update`.

SHA256:
`445b3fac779236d95e82ea535e7cf365a8e0356249d461f4c2d1c1c0b1d7e918`

## 1.5.0

Items **28–32** (numbers **1–27** did not shift):

1. **28** / `users` — list, create, enable/disable, subscription URL. Does not show the admin password.
2. **29** / `nodes` — list, disable/enable/restart one node, change address (`PATCH /nodes/` with uuid in JSON).
3. **30** / `telegram` + `backup-remote` — Telegram from the menu (token not in the log); healthcheck at most once an hour: panel API, certificate < 21 days, node not Connected; rclone+age at 02:00 or immediately.
4. **31** / `certs` — Let’s Encrypt days left, `certbot renew` now, force-renew, copy into `/dev/shm`. Menu header shows the nearest expiry.
5. After item **25** on the panel — a checklist: UUID and `node-transports apply` on the node VPS.
6. **32** / `firewall` — ADMIN_IP, rebuild UFW.
7. Item **23** / `admin-login`: panel login once, only after the word **SHOW**, only on a TTY, not written to `/var/log/remnawave-manager.log`.

SHA256:
`72c9cb8ca9ac35bb03b596bb32d68ff507c43f36992d1ee615962da3f44bacdb`

## 1.4.4

Item **25**: after picking a node, `[0]` returns to the node list, not the main menu. `q` in the list (and in transports) leaves to the main menu. A selected node UUID no longer skips the list on the next visit. After add/remove the transports menu stays on that node.

SHA256:
`c94a44bf4c9e5930593bfe2227b14fed1e495efd72d300ba857aa10778d37a0d`

Docs (script hash unchanged): full menu items 0–27 in English and Russian in the README and `docs/MENU.*`; repository license is MIT.

## 1.4.3

Item **25** always offers a node (number, UUID, or 0 = all), not only when there is more than one. The GitHub cache no longer hides a new Latest if the local version matched the previous check (the menu said “up to date 1.4.1” after 1.4.2 was already out). Menu header: `sub ● 000000` fixed. Removing transports behaves as in 1.4.2.

SHA256:
`90dfaf451da9ec826cef431162ce3f6f59658c7aa7727b563e07a101eef89922`

## 1.4.2

Item **25** actually removes transports. `sync_node_transports` after “remove Hysteria2” re-read `manager.env` and set HYSTERIA2=1 again, so the profile, hosts and sing-box stayed as they were. An explicit add/remove is now kept and written to env before hydrate.

SHA256:
`f0ceb92599ccbe8e9427ad3e506938ffcb6f63ef8aee989ce5a951290171205b`

## 1.4.1

`self-update` after install no longer fails with “Unknown command: --lang ru”. The script `IFS` has no space, and 1.4.0 glued `--lang ru` into one argument. 1.4.1 accepts that argv and passes the language as two words.

SHA256:
`89bc7d2c2853925cd4cd18f5bf57a7d83cc2bb3cb73a38fb18a590957e9a1d57`

## 1.4.0

An unknown command no longer dumps the whole `--help` (short text plus a `self-update` hint). `--version` without sudo. Item **26** updates this script (item **24** is author modules). Item **27** / `add-node` registers a node on the panel via API without `apt full-upgrade`. Preflight DNS/80/443/disk/Docker before install. Item **25** offers a node UUID when there are several (`0` = all). Doctor: script version vs GitHub Latest, Let’s Encrypt days left, UDP/443 and TCP/8443/4443, Connected nodes via API. ok/warn/die messages go through `t()`.

SHA256:
`fe91e431c96d54efed1a1d7219349578733d5fd30d9ab744f1436c3602be24de`

## 1.3.0

Automatic script update check: opening the menu compares `VERSION` with GitHub Latest. If a newer one exists, it offers to install. 6-hour cache in `manager.env`. CLI: `check-update`, `check-update --apply`, `--no-update-check`. Item 24 → “3) check for an update”.

SHA256:
`dd7ece932c3dd26a93dacc0c24249dfa1b15bb8f7bd475b5b846a6d6a933c152`

## 1.2.0

Menu item **25** / `node-transports`: add or remove xHTTP, gRPC and Hysteria2 on an already installed node, including a node on another server. On the panel the profile, inbounds, hosts and squad are updated (extra hosts are pruned). On the node — UFW, certificates in `/dev/shm` and the sing-box stack. Adding one transport does not turn the others back on. Item 4 (`protocols` / `bind`) is still a full auto-bind.

SHA256:
`f5fe62ececf0fe5261a801bde4be0b325273b1761d7ee731df138a7fa19ca3b2`

## 1.1.0

Author — **Corgi Lusi**. All features in one script. Blue menu. Item **24** / `community-update` downloads the original Rezzosoft, eGames and DigneZzZ files (authorship kept); `self-update` takes this script from GitHub Latest.

SHA256:
`82f4c523ef22167c83b841c7631bc7fd82ff798a7ef2f0681f0515406ca7817f`

## 1.0.0

First stable release without a `-prod` suffix. Same installer as 25.2.7: Reality with firefox fingerprint, CorgiLusi squad, a dedicated profile per node, run without `sudo` in the command.

SHA256:
`79cec67577feb666bc89a35452909457dba169540cecf909d8b2932f552fbe07`

## 25.2.7-prod

Reality hosts (VLESS TCP, gRPC, xHTTP) are created with uTLS fingerprint **firefox**, not chrome. Hysteria2 does not set a fingerprint. On an already installed panel: item 4 / `bash remnawave-manager.sh protocols`.

SHA256:
`14704ad33250669ac1d9d95d5677cc53fb007dc87932d655843a68be4a2ac875`

## 25.2.6-prod

Run without `sudo` in the command: `bash remnawave-manager.sh`. If you are not root, the script re-execs via sudo. `--help` does not ask for a password.

SHA256:
`5116f5be95419515f63d9546ce626ad425c3a216648a99964d5244a86ee4cedd`

## 25.2.5-prod

Squad and profiles are named **CorgiLusi**, not AUTO. Each node has its own config profile. Right after install **Default-Profile** (and a squad with that name) is removed. An old AUTO-PROFILE is renamed to CorgiLusi on `protocols` / item 4.

SHA256:
`d428f8fac02c9904a8dec07b585fc8f0ecafd561482b1a72c8be756c101e65e2`

## 25.2.4-prod

`repair` no longer requires a filled `manager.env`. Domains are recovered from the panel `.env`, `credentials.txt`, nginx and Let's Encrypt. `--lang` does not create an empty env that made item 7 fail with “no DOMAIN_PANEL”. `manager.env` is no longer `source`d — passwords with `$` and `&` no longer break domain loading.

SHA256:
`0bb8ed6ec6c46a8fc02947f3a1fe45c1a3dbc2de9555cc63e5989336e4c229da`

## 25.2.3-prod

Bilingual menu with live status and live-VPS fixes: subscription 502, `curl: (52) Empty reply`, `"-":0: bad minute` in crontab.

- menu: frame, TTY color, two lines per item, panel/sub/node header, item 23 “URLs”;
- choosing “full install” again on an existing panel offers repair / bind, not `apt full-upgrade`;
- the subscription page talks to the panel via `https://DOMAIN_PANEL` + `extra_hosts` (ProxyCheck no longer tears the socket);
- `wait_subscription` does not spam curl 52 and does not abort the install;
- Hysteria2 certificates are copied by a systemd timer, not `crontab -` (empty stdin under `set -e` caused bad minute and aborted `protocols`).

SHA256:
`728536ee926faba23dbb642383e9320c7d37a2e3c3eb275081edce2c55cef8a8`

## 25.2.2-prod

Interactive menu with a description of every function and UI language (English / Russian). GitHub has two READMEs: [English](README.md) and [Русский](README.ru.md).

- menu item 22, `--lang en|ru` and `RW_LANG` in `manager.env`;
- the menu covers install, bind, status/doctor/repair, up/down/restart, backup/restore, update, uninstall, Xray core, add-ons, stealth, CLI and the converter;
- `--help` is printed in the selected language.

SHA256:
`989c56497e2fbf8877b5e43deb3c771bfa78a402d79b9548791cd13b6299f7c9`

## 25.2.1-prod

Fully automatic bind with no panel UI edits and no converter.

- profile/node/host UPDATE goes to the collection (`PATCH /config-profiles/`, `PATCH /nodes/`, `PATCH /hosts/`) with `uuid` in JSON, as in backend-contract 3.4.x;
- after a profile update every inbound UUID is attached to nodes (`POST /nodes/bulk-actions/profile-modification`, fallback — PATCH each node);
- hosts are created with `path`/`host` for gRPC and xHTTP, `alpn=h3` for Hysteria2 and a `nodes` array;
- the AUTO squad gets every inbound; the AUTO user and subscription URL appear without the UI;
- by default Reality + Hysteria2 + gRPC + xHTTP are on (`--reality-only` for Reality only).

On an existing 25.2.0: download `@v25.2.1-prod` and run `bash remnawave-manager.sh protocols`.

SHA256:
`534353340dc8987375f5bc45242f01a97327c8d8713bfc5628f1884f891e7e60`

## 25.2.0-prod

Russian menu and multi-protocol. Panel and node can be installed on separate servers. Rezzosoft KVN, eGamesAPI and DigneZzZ features are in the installer (authorship kept).

- menu with no arguments; `install panel` / `install node`; Reality, Hysteria2, gRPC, xHTTP;
- converter https://rezzosoft.ru/converter.html in the menu and help;
- `/dev/shm` and Let's Encrypt in the node compose, Hysteria2 certificate cron;
- `up`/`down`/`restart`/`logs`, `stealth`, `install-script`, Cloudflare DNS when `CLOUDFLARE_API_TOKEN` is set.

SHA256:
`86ffcb6e7ff764125ccf2f38feb9c737e9b7ae579d86519f9ce8019adad06211`

## 25.1.16-prod

After 25.1.15 the panel answers 200, the subscription page stayed on 502: `repair` did not bring up `remnawave-subscription-page`. The container exits on start if the API token cannot read `/system/metadata` (`exit(1)`). `CUSTOM_SUB_PREFIX=sub` hid the UI from the domain root.

- `repair` checks the token via `/system/metadata`, creates a new one if needed, rewrites `.env` and `docker compose up --force-recreate --wait`;
- `CUSTOM_SUB_PREFIX` is empty, `SUB_PUBLIC_DOMAIN` = subscription domain without `/sub` (same as the official bundled layout);
- `curl -I https://sub.example.com` should be HTTP 200.

SHA256:
`b3d8293bb4735f48b21e456860585a80e9c9a8102f33c5b8917b8bac259197b8`

## 25.1.15-prod

Ubuntu nginx 1.24 does not know the `http2 on;` directive (it appeared in 1.25.1). Vhosts use `listen ... ssl http2;` again.

SHA256:
`15ad868699b467264ffda6354b94cf9fc6961b02569adcce36c480c131464835`

## 25.1.14-prod

`repair` can no longer break nginx: `/etc/nginx/conf.d/ssl-params.conf` is restored immediately as an empty stub if 25.1.12 deleted it. Download the release from GitHub Releases, not from a cached `raw.githubusercontent.com`.

SHA256:
`e94215cc2dfb6e829ee8af449569d43b0d2f1e910017c8ebc40a1766d9f0e6a0`

## 25.1.13-prod

`repair` hotfix after 25.1.12: `/etc/nginx/conf.d/ssl-params.conf` was deleted before `reality-site.conf` was rewritten, `nginx -t` failed, the panel stayed on 502.

- old `include .../ssl-params.conf` lines are rewritten to the snippet **before** the file is removed;
- `repair` applies nginx only after every vhost is written.

SHA256:
`c868a4970404dc9ae37d687f49e780a6de9ee8698115604cde1999c816b7148b`

## 25.1.12-prod

HTTP 502 fix on the panel and subscription page; Reality SNI camouflage is a Corgi kennel site.

- nginx no longer uses Ubuntu `proxy_params`: official Remnawave headers go upstream (`Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host`) and `proxy_http_version 1.1`, otherwise ProxyCheckMiddleware on the panel and subscription-page tears the socket → nginx 502;
- TLS parameters live in `/etc/nginx/snippets/` so Ubuntu does not include them twice from `conf.d/` (duplicate TLSv1.2/1.3 and a bloated `proxy_headers_hash`);
- default SelfSteal template is the **Corgi Lusi** kennel site (`corgi|simple|business|nothing`);
- `repair` rewrites nginx and the camouflage site on an already installed VPS without Docker/DB;
- `ssh_ports | head` no longer aborts install via SIGPIPE/`set -o pipefail`.

On an existing `25.1.11-prod`: `bash remnawave-manager.sh repair`.

SHA256:
`45e5029aa29f21b587a2726bdf191305ab4fd855e85548b73e010e8982bec3bb`

## 25.1.11-prod

Installer fixes on top of `25.1.10-prod` (automatic OS upgrade kept).

- On one VPS the Node is registered via the `remnawave-network` Docker gateway, not `127.0.0.1` (the panel container cannot reach host-network remnanode on loopback);
- UFW in `single` mode opens Node port 2222 only from the Docker subnet;
- `install panel` brings up the SNI router on TCP/443;
- `ssl_reject_handshake` is used on nginx ≥ 1.19.4, otherwise a dummy certificate and `return 444`;
- Hysteria2: `sing-box run -c /etc/sing-box/config.json`;
- Prometheus scrapes host-network node-exporter as `host.docker.internal:9100`;
- panel `.env` sets `REDIS_SOCKET=/var/run/valkey/valkey.sock` explicitly;
- `manager.env` is updated by key (upsert);
- API token creation is resilient to a taken name (`name <= 30`);
- admin username is no longer taken as the full email;
- admin password is checked against backend rules (24+ / letter / digit);
- restore `.age` is detected by extension;
- `--admin-ip` and fail2ban account for every SSH port;
- a custom Xray core is mounted into the existing node compose `volumes:`;
- `apt-get full-upgrade` from 25.1.10 is kept (no automatic reboot).

SHA256:
`e10193fd771c386af76697b0bc42c1eddb831b21cf1d60341f6f6fe43269d239`

## 25.1.10-prod

Automatic full OS update during installation.

- runs `apt-get update` before installing dependencies;
- runs `dpkg --configure -a`;
- runs `apt-get -f install -y`;
- runs `apt-get full-upgrade -y`;
- runs `apt-get autoremove --purge -y` and `apt-get autoclean -qq`;
- does not reboot automatically; reports `/var/run/reboot-required` when present.

SHA256:
`97a9a6cdfb5d203c35e43eee87ef8977ec34e3054a9fa5ca64dfc031fedb9255`

## 25.1.9-prod

Firewall/SSH bootstrap hotfix.

- fixed SSH port detection when `sshd -T` returns no `port`;
- added fallbacks for `/etc/ssh/sshd_config` and systemd socket activation;
- UFW opens all detected SSH ports before enabling the firewall;
- preserved bootstrap ADMIN/API token fixes from 25.1.7 and 25.1.8.

SHA256:
`04edbee57c6fb0250d6d6c1e8e967553ebc37462a11460e95038068921603086`

## 25.1.8-prod

Bootstrap/API token compatibility hotfix.

- automatic API token name stays within backend `name <= 30`;
- fixed bootstrap of the minimal API token for Subscription Page.

SHA256:
`1271774b70e4f4c0b4f8574e25248b665547bc90aac2b6e59ce5d8e2824b46aa`

## 25.1.7-prod

Bootstrap persistence hotfix.

- `ADMIN_PASSWORD` is saved to `/opt/remnawave/manager.env` before API login/register;
- reruns after a partial bootstrap use the same password.

SHA256:
`6d7920b94652dce6b8ef17a9cbbbfcacaf975a3280294998ce756b73a15d6f4a`
