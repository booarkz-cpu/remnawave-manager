# Security Policy

[English](SECURITY.md) · [Русский](SECURITY.ru.md)

This file is the English security section for Remnawave Manager (Corgi Lusi). Report sensitive issues privately — do not open a public GitHub issue with exploit details.

## Secrets — never publish

Do not put any of the following in Git, issues, PRs, chat, screenshots, or pastebins:

- GitHub personal access tokens
- Remnawave API tokens and admin JWT
- Node `SECRET_KEY`
- PostgreSQL password
- Panel admin password
- age private key (`/opt/remnawave/backup-age.key`)
- Hysteria2 password
- Telegram bot token
- Cloudflare API token
- Contents of `/opt/remnawave/credentials.txt` and `/opt/remnawave/manager.env`

Menu **23** / `admin-login SHOW` prints the panel login **once on a TTY**. That password is **not** written to `/var/log/remnawave-manager.log`. Telegram tokens are not printed in the log.

## User cabinet (1.6.0)

The cabinet at `/lk/` stores accounts in SQLite (`/opt/remnawave/cabinet/data`). Passwords use PBKDF2. Session cookies are HttpOnly. Admin settings **do not** return OAuth secrets or Remnawave tokens. Checkout does **not** load payment-gateway SDKs (mock or manual). Test mode (`remnawave-cabinet-test.sh`) never talks to real Telegram/VK/Yandex apps. Put OAuth client secrets only in the cabinet `.env` or the admin form; do not paste them into issues.

## Who may change this repository

Official branches, tags and GitHub Releases are written only by **Corgi Lusi (`booarkz-cpu`)** and by the Cursor agent using that account. GitHub rulesets block everyone else from creating, updating, force-pushing or deleting branches and tags. Do not merge pull requests from people you do not know. A public repository can still be forked; forks cannot write back here. Wiki editing is off. GitHub Actions may use GitHub-owned actions only, with a read-only default token.

## How the installer stores configuration

`/opt/remnawave/manager.env` is **not** `source`d. Passwords may contain `$`, `&`, backticks and backslashes; a naive `source` would abort the rest of the file (domains never load) or spawn jobs. The installer parses `KEY=VALUE` lines and **refuses** to overwrite shell/installer keys: `VERSION`, `PATH`, `HOME`, `IFS`, `LD_PRELOAD`, `DRY_RUN`, `AUTO_YES`, and similar. CLI `KEY=VALUE` arguments use the same denylist.

Ubuntu `/etc/os-release` is not sourced (it sets `VERSION=` and would clobber `--version`).

## Production checklist

- Download **GitHub Latest** and compare SHA256 with `SHA256SUMS` (see README). Do not trust a cached `raw.githubusercontent.com/main` copy.
- Restrict SSH (`ADMIN_IP`, menu **32** / `firewall`).
- On a split install, allow node port **2222** only from the panel IP.
- Test `backup` / `restore` before you need them. Off-site copies: rclone + age (`backup-remote`).
- Review third-party add-ons from menu **24** under **their** licenses; this repo does not relicense them.
- Pin upstream image tags when you need a reproducible panel, instead of floating `latest`, if your operations require it.
- Delete `credentials.txt` after you have stored the secrets somewhere safe.

## Subscription-domain stub (1.5.5)

Menu **33** / `sub-stub` publishes a public kennel site at `https://DOMAIN_SUB/`. Files live in `/var/www/sub-site` (HTML, CSS, JPEG/SVG). That tree has **no tokens or passwords**. Paths that are not stub files — including `/shortUuid` — still proxy to the Remnawave subscription page. Do not put secrets in `/var/www/sub-site`.

## Menu and API

- Creating a user (menu **28**) sets `expireAt`, optional `trafficLimitBytes`, and optional `hwidDeviceLimit`. A device limit of `0` omits the HWID field (no cap). Traffic `0` is unlimited.
- `self-update` replaces the installer file after `bash -n`. It does not run inside the menu subshell (`exec` must replace the running process).
- Failed menu actions (`die`, API errors) return to the menu; they must not take down the whole process.

## Reporting a vulnerability

For issues that can leak credentials, bypass the firewall, or execute unexpected commands: contact the repository owner privately. Do not publish a working exploit before a fix is out.

There is **no warranty**. MIT license: [LICENSE](LICENSE).
