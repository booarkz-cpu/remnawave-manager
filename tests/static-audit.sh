#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SCRIPT=remnawave-manager-v1.5.1.sh

echo "[1/18] bash -n current + historical"
bash -n "$SCRIPT"
bash -n remnawave-manager.sh
bash -n remnawave-manager-v1.5.1.sh
bash -n remnawave-manager-v1.5.0.sh
bash -n remnawave-manager-v1.4.4.sh
bash -n remnawave-manager-v1.4.3.sh
bash -n remnawave-manager-v1.4.2.sh
bash -n remnawave-manager-v1.4.1.sh
bash -n remnawave-manager-v1.4.0.sh
bash -n remnawave-manager-v1.3.0.sh
bash -n remnawave-manager-v1.2.0.sh
bash -n remnawave-manager-v1.1.0.sh
bash -n remnawave-manager-v1.0.0.sh
bash -n remnawave-manager-v25.2.7-prod.sh
bash -n remnawave-manager-v25.2.6-prod.sh
bash -n remnawave-manager-v25.2.5-prod.sh
bash -n remnawave-manager-v25.2.4-prod.sh
bash -n remnawave-manager-v25.2.3-prod.sh
bash -n remnawave-manager-v25.2.2-prod.sh
bash -n remnawave-manager-v25.2.1-prod.sh
bash -n remnawave-manager-v25.2.0-prod.sh
for f in remnawave-manager-v25.1.{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}-prod.sh; do
  bash -n "$f"
done

echo "[2/18] help"
bash "$SCRIPT" --help >/tmp/rw-help.txt
grep -Fq 'rezzosoft.ru/converter.html' /tmp/rw-help.txt
grep -Fq repair /tmp/rw-help.txt
grep -Fq bind /tmp/rw-help.txt
grep -Fq -- '--all-protocols' /tmp/rw-help.txt

echo "[3/18] dry-run single (no sudo prefix — script elevates itself)"
bash "$SCRIPT" install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null

echo "[4/18] dry-run panel + node"
bash "$SCRIPT" install panel --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com >/dev/null
bash "$SCRIPT" install node --dry-run --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret --grpc --xhttp --hysteria2 >/dev/null

echo "[5/18] SSH port fallback"
grep -Fq 'ssh_ports()' "$SCRIPT"
grep -Fq 'ssh_port_list()' "$SCRIPT"
grep -Fq 'systemctl show ssh.socket' "$SCRIPT"
grep -Fq "ports='22'" "$SCRIPT"

echo "[6/18] Node is not created on 127.0.0.1"
if grep -n "create_node '127.0.0.1'" "$SCRIPT"; then
  echo 'FAIL: panel container cannot reach host loopback' >&2
  exit 1
fi
grep -Fq 'node_host_address()' "$SCRIPT"
grep -Fq 'docker_node_subnet()' "$SCRIPT"

echo "[7/18] Panel mode publishes HTTPS on 443"
awk '/^install_panel\(\)/,/^install_edge\(\)/' "$SCRIPT" | grep -Fq 'write_sni_router 0'
grep -Fq 'write_reject_vhost' "$SCRIPT"

echo "[8/18] Hysteria2 / Prometheus / Redis / restore / OS upgrade"
grep -Fq 'command: ["run","-c","/etc/sing-box/config.json"]' "$SCRIPT"
grep -Fq "host.docker.internal:9100" "$SCRIPT"
grep -Fq 'set_env REDIS_SOCKET /var/run/valkey/valkey.sock' "$SCRIPT"
grep -Fq '[[ "$archive" == *.age ]]' "$SCRIPT"
grep -Fq 'persist_manager' "$SCRIPT"
grep -Fq 'apt-get full-upgrade -y -qq' "$SCRIPT"
grep -Fq 'apt-get autoremove --purge -y -qq' "$SCRIPT"
grep -Fq '/var/run/reboot-required' "$SCRIPT"

echo "[9/18] nginx ProxyCheck headers + Corgi SelfSteal + repair"
grep -Fq 'snippets/remnawave-proxy.conf' "$SCRIPT"
grep -Fq 'X-Forwarded-Proto https' "$SCRIPT"
grep -Fq 'proxy_http_version 1.1' "$SCRIPT"
grep -Fq 'Corgi Lusi' "$SCRIPT"
grep -Fq "SELFSTEAL_TEMPLATE:-corgi" "$SCRIPT"
grep -Fq 'repair()' "$SCRIPT"
grep -Fq 'migrate_ssl_params_includes' "$SCRIPT"
grep -Fq 'NGINX_SKIP_RELOAD' "$SCRIPT"
grep -Fq 'Compatibility stub' "$SCRIPT"
grep -Fq 'listen 127.0.0.1:9443 ssl http2;' "$SCRIPT"
if grep -nE '^[[:space:]]*http2 on;' "$SCRIPT"; then
  echo 'FAIL: standalone http2 on; is not supported by Ubuntu nginx 1.24' >&2
  exit 1
fi
if grep -n 'include /etc/nginx/proxy_params' "$SCRIPT"; then
  echo 'FAIL: Ubuntu proxy_params is not sufficient for ProxyCheckMiddleware' >&2
  exit 1
fi

echo "[10/18] subscription-page token check + empty CUSTOM_SUB_PREFIX"
grep -Fq 'sub_token_can_read_metadata' "$SCRIPT"
grep -Fq 'GET /system/metadata' "$SCRIPT"
grep -Fq 'ensure_subscription()' "$SCRIPT"
grep -Fq 'wait_subscription()' "$SCRIPT"
grep -Fq 'CUSTOM_SUB_PREFIX=' "$SCRIPT"
if grep -n 'CUSTOM_SUB_PREFIX=sub' "$SCRIPT"; then
  echo 'FAIL: CUSTOM_SUB_PREFIX=sub hides the page at /' >&2
  exit 1
fi
grep -Fq 'set_env SUB_PUBLIC_DOMAIN "${DOMAIN_SUB}"' "$SCRIPT"

echo "[11/18] Rezzosoft / gRPC / xHTTP / menu / credits"
grep -Fq 'rezzosoft.ru/converter.html' "$SCRIPT"
grep -Fq 'Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2' "$SCRIPT"
grep -Fq 'eGamesAPI/remnawave-reverse-proxy' "$SCRIPT"
grep -Fq 'DigneZzZ/remnawave-scripts' "$SCRIPT"
grep -Fq 'ENABLE_GRPC' "$SCRIPT"
grep -Fq 'ENABLE_XHTTP' "$SCRIPT"
grep -Fq 'VLESS_GRPC_REALITY' "$SCRIPT"
grep -Fq 'VLESS_XHTTP_REALITY' "$SCRIPT"
grep -Fq 'interactive_menu()' "$SCRIPT"
grep -Fq 'install node' "$SCRIPT"
grep -Fq '/dev/shm:/dev/shm' "$SCRIPT"

echo "[12/18] automatic API bind (no panel UI)"
grep -Fq 'bind_all()' "$SCRIPT"
grep -Fq 'ensure_internal_squad()' "$SCRIPT"
grep -Fq 'PATCH /nodes/' "$SCRIPT"
grep -Fq 'PATCH /config-profiles/' "$SCRIPT"
grep -Fq 'PATCH /hosts/' "$SCRIPT"
grep -Fq "fp='firefox'" "$SCRIPT"
if grep -n 'fingerprint:"chrome"' "$SCRIPT"; then
  echo 'FAIL: Reality host fingerprint must be firefox, not chrome' >&2
  exit 1
fi
grep -Fq '/internal-squads/' "$SCRIPT"
grep -Fq 'create_auto_user()' "$SCRIPT"
grep -Fq 'CorgiLusi' "$SCRIPT"
grep -Fq 'Корги Люси' "$SCRIPT"
grep -Fq 'Corgi Lusi' "$SCRIPT"
grep -Fq 'refresh_community_modules()' "$SCRIPT"
grep -Fq 'self_update()' "$SCRIPT"
grep -Fq 'community-update' "$SCRIPT"
grep -Fq 'remove_default_profile_and_squads()' "$SCRIPT"
grep -Fq 'Default-Profile' "$SCRIPT"
grep -Fq 'profile_name_for_node()' "$SCRIPT"
grep -Fq 'canonical_node_name()' "$SCRIPT"
grep -Fq 'is_discard_name()' "$SCRIPT"
grep -Fq 'persist_protocol_flags()' "$SCRIPT"
grep -Fq 'prune_protocol_hosts()' "$SCRIPT"
grep -Fq 'apply_local_node_transports()' "$SCRIPT"
grep -Fq 'sync_node_transports()' "$SCRIPT"
grep -Fq 'node_transports_menu()' "$SCRIPT"
grep -Fq 'node_transports_cli()' "$SCRIPT"
grep -Fq 'check_self_update()' "$SCRIPT"
grep -Fq 'fetch_latest_tag()' "$SCRIPT"
grep -Fq 'version_is_newer()' "$SCRIPT"
grep -Fq 'maybe_prompt_self_update()' "$SCRIPT"
grep -Fq 'check-update' "$SCRIPT"
grep -Fq -- '--no-update-check' "$SCRIPT"
grep -Fq 'ufw_toggle()' "$SCRIPT"
if grep -nE 'Default Profile\)' "$SCRIPT"; then
  echo 'FAIL: unquoted space in case pattern breaks bash -n' >&2
  exit 1
fi
if grep -nE 'PATCH "/nodes/\$\{' "$SCRIPT"; then
  echo 'FAIL: node UPDATE must PATCH /nodes/ with uuid in the JSON body' >&2
  exit 1
fi
if grep -nE 'PATCH "/config-profiles/\$\{' "$SCRIPT"; then
  echo 'FAIL: config profile UPDATE must PATCH /config-profiles/ with uuid in the JSON body' >&2
  exit 1
fi
if grep -n 'привяжите inbound' "$SCRIPT"; then
  echo 'FAIL: installer still asks the user to bind inbounds in the panel' >&2
  exit 1
fi

echo "[13/18] bilingual menu + README + domain hydrate"
grep -Fq 'print_menu()' "$SCRIPT"
grep -Fq 'choose_language()' "$SCRIPT"
grep -Fq -- '--lang|--language' "$SCRIPT"
grep -Fq 'RW_LANG' "$SCRIPT"
grep -Fq 'remnawave-hysteria-certs' "$SCRIPT"
grep -Fq 'extra_hosts' "$SCRIPT"
grep -Fq 'existing_install_choice' "$SCRIPT"
grep -Fq 'host.docker.internal:host-gateway' "$SCRIPT"
grep -Fq 'hydrate_install_state()' "$SCRIPT"
grep -Fq 'load_kv_file()' "$SCRIPT"
grep -Fq 'ensure_repair_domains()' "$SCRIPT"
grep -Fq 'elevate_if_needed()' "$SCRIPT"
grep -Fq 'wants_help_only()' "$SCRIPT"
if grep -nE '^sudo bash remnawave-manager.sh' README.md README.ru.md; then
  echo 'FAIL: README must invoke the script without a sudo prefix' >&2
  exit 1
fi
if grep -nE '\(crontab -l .*; echo' "$SCRIPT"; then
  echo 'FAIL: user crontab pipe under set -e installs an empty crontab' >&2
  exit 1
fi
if grep -nE 'source "\$ENV_FILE"' "$SCRIPT"; then
  echo 'FAIL: manager.env must not be sourced (passwords can contain $ and &)' >&2
  exit 1
fi
test -f README.md
test -f README.ru.md
test -f docs/GUIDE.en.md
test -f docs/GUIDE.ru.md
test -f docs/MENU.en.md
test -f docs/MENU.ru.md
test -f LICENSE
grep -Fq 'MIT License' LICENSE
grep -Fq 'Copyright (c) 2026' LICENSE
grep -Fq '[LICENSE](LICENSE)' README.md README.ru.md
grep -Fq 'docs/MENU.en.md' README.md docs/GUIDE.en.md
grep -Fq 'docs/MENU.ru.md' README.ru.md docs/GUIDE.ru.md
grep -Fq '### 1. Full install' README.md
grep -Fq '### 1. Полная установка' README.ru.md
grep -Fq '### 25. Node transports' README.md
grep -Fq '### 25. Транспорты ноды' README.ru.md
grep -Fq '### 28. Users' README.md
grep -Fq '### 32. Firewall' README.md
grep -Fq '### 28. Пользователи' README.ru.md
grep -Fq '### 32. Файрвол' README.ru.md
grep -Fq '## 28. Users' docs/MENU.en.md
grep -Fq '## 32. Firewall' docs/MENU.en.md
grep -Fq '## 28. Пользователи' docs/MENU.ru.md
grep -Fq '## 32. Файрвол' docs/MENU.ru.md
grep -Fq 'admin-login SHOW' docs/MENU.en.md docs/GUIDE.en.md
grep -Fq '## License' README.md
grep -Fq '## Лицензия' README.ru.md
grep -Fq '[English](README.md)' README.md
grep -Fq '[Русский](README.ru.md)' README.md
grep -Fq '[English](README.md)' README.ru.md
grep -Fq 'docs/GUIDE.en.md' README.md
grep -Fq 'docs/GUIDE.ru.md' README.ru.md
grep -Fq 'check-update --apply' README.md README.ru.md docs/GUIDE.en.md docs/GUIDE.ru.md
grep -Fq 'self-update' README.md README.ru.md docs/GUIDE.en.md docs/GUIDE.ru.md
grep -Fq 'releases/latest/download/remnawave-manager.sh' README.md README.ru.md docs/GUIDE.en.md docs/GUIDE.ru.md
if grep -nE '^sudo bash remnawave-manager.sh' README.md README.ru.md docs/GUIDE.en.md docs/GUIDE.ru.md docs/MENU.en.md docs/MENU.ru.md; then
  echo 'FAIL: docs must invoke the script without a sudo prefix' >&2
  exit 1
fi
if grep -nE 'remawve-manager' README.md README.ru.md docs/GUIDE.en.md docs/GUIDE.ru.md docs/MENU.en.md docs/MENU.ru.md; then
  echo 'FAIL: typo remawve-manager in docs' >&2
  exit 1
fi
bash "$SCRIPT" --lang en --help >/tmp/rw-help-en.txt
grep -Fq 'interactive menu with descriptions' /tmp/rw-help-en.txt
grep -Fq -- '--lang en|ru' /tmp/rw-help-en.txt
grep -Fq 'urls | health' /tmp/rw-help-en.txt
grep -Fq 'Do not prefix the command with sudo' /tmp/rw-help-en.txt
grep -Fq 'community-update' /tmp/rw-help-en.txt
grep -Fq 'Corgi Lusi' /tmp/rw-help-en.txt
grep -Fq 'node-transports' /tmp/rw-help-en.txt
grep -Fq 'grpc|xhttp|hysteria2|all' /tmp/rw-help-en.txt
grep -Fq 'check-update' /tmp/rw-help-en.txt
grep -Fq -- '--no-update-check' /tmp/rw-help-en.txt
grep -Fq -- '--version' /tmp/rw-help-en.txt
grep -Fq 'add-node' /tmp/rw-help-en.txt
grep -Fq 'users list' /tmp/rw-help-en.txt
grep -Fq 'admin-login' /tmp/rw-help-en.txt
bash "$SCRIPT" --version | grep -Fq '1.5.1'
set +e
bash "$SCRIPT" --lang en nosuchcmd >/tmp/rw-unk.txt 2>&1
unk_rc=$?
set -e
[[ "$unk_rc" -eq 2 ]]
grep -Fq 'Unknown command' /tmp/rw-unk.txt
if grep -Fq 'panel + node on one server' /tmp/rw-unk.txt; then
  echo 'FAIL: unknown command dumped full --help' >&2
  exit 1
fi
# 1.4.0 self-update restart glued `--lang ru` into one argv because IFS has no space.
bash "$SCRIPT" '--lang ru' --no-update-check --version >/tmp/rw-lang-glue.txt 2>&1
grep -Fq '1.5.1' /tmp/rw-lang-glue.txt
if grep -Fq 'Unknown command' /tmp/rw-lang-glue.txt; then
  echo 'FAIL: glued --lang ru treated as unknown command' >&2
  exit 1
fi
if grep -Fq '${RW_LANG:+--lang' "$SCRIPT"; then
  echo 'FAIL: self_update must not unquote --lang under IFS without space' >&2
  exit 1
fi
grep -Fq 'exec bash "$dest" --lang "$RW_LANG" --no-update-check' "$SCRIPT"
grep -Fq 'snapshot_protocol_flags()' "$SCRIPT"
grep -Fq 'restore_protocol_flags()' "$SCRIPT"
awk '/^set_transport\(\)/,/^snapshot_protocol_flags\(\)/' "$SCRIPT" | grep -Fq persist_protocol_flags
awk '/^sync_node_transports\(\)/,/^apply_protocols\(\)/' "$SCRIPT" | grep -Fq restore_protocol_flags
grep -Fq 'nt_pick_none' "$SCRIPT"
grep -Fq 'nt_q' "$SCRIPT"
awk '/^pick_target_node\(\)/,/^add_node_menu\(\)/' "$SCRIPT" | grep -Fq "TARGET_NODE_UUID=''"
awk '/^node_transports_menu\(\)/,/^node_transports_cli\(\)/' "$SCRIPT" | grep -Fq 'while true'
if awk '/^pick_target_node\(\)/,/^add_node_menu\(\)/' "$SCRIPT" | grep -q 'TARGET_NODE_UUID:-}" \]\] && return 0'; then
  echo 'FAIL: pick_target_node must not skip the list when a UUID is already set' >&2
  exit 1
fi
grep -Fq 'version_is_newer()' "$SCRIPT"
grep -Fq 'http_first_redirect()' "$SCRIPT"
grep -Fq 'tag_from_github_url()' "$SCRIPT"
grep -Fq 'download_self_script()' "$SCRIPT"
grep -Fq 'JSDELIVR_LATEST_URL' "$SCRIPT"
grep -Fq 'check_update_cli || true' "$SCRIPT"
grep -Fq 'check_update_cli "${2:-}" || exit $?' "$SCRIPT"
grep -Fq 'release-assets.githubusercontent.com' "$SCRIPT"
if awk '/^fetch_latest_tag\(\)/,/^persist_update_check\(\)/' "$SCRIPT" | grep -q 'url_effective'; then
  echo 'FAIL: fetch_latest_tag must not use the final GitHub asset CDN URL' >&2
  exit 1
fi
awk '/^probe_http_code\(\)/,/^subscription_panel_url\(\)/' "$SCRIPT" | grep -Fq '^[0-9]{3}$'
grep -Fq 'preflight()' "$SCRIPT"
grep -Fq 'pick_target_node()' "$SCRIPT"
grep -Fq 'add_node_menu()' "$SCRIPT"
grep -Fq 'script_update_menu()' "$SCRIPT"
grep -Fq 'unknown_cmd()' "$SCRIPT"
grep -Fq 'print_version()' "$SCRIPT"
grep -Fq 'cert_days_left()' "$SCRIPT"
grep -Fq 'TARGET_NODE_UUID' "$SCRIPT"
grep -Fq 'menu_row 26' "$SCRIPT"
grep -Fq 'menu_row 27' "$SCRIPT"
grep -Fq 'menu_row 28' "$SCRIPT"
grep -Fq 'menu_row 32' "$SCRIPT"
grep -Fq 'users_menu()' "$SCRIPT"
grep -Fq 'node_control_menu()' "$SCRIPT"
grep -Fq 'alerts_backup_menu()' "$SCRIPT"
grep -Fq 'certs_menu()' "$SCRIPT"
grep -Fq 'firewall_menu()' "$SCRIPT"
grep -Fq 'show_admin_login_once()' "$SCRIPT"
grep -Fq 'print_node_apply_hint()' "$SCRIPT"
grep -Fq 'write_health_notify_script()' "$SCRIPT"
grep -Fq 'say_tty()' "$SCRIPT"
grep -Fq 'TELEGRAM_ALERTS' "$SCRIPT"
grep -Fq 'BACKUP_REMOTE' "$SCRIPT"
grep -Fq 'ADMIN_IP' "$SCRIPT"
awk '/^show_admin_login_once\(\)/,/^urls_and_optional_admin\(\)/' "$SCRIPT" | grep -Fq say_tty
if awk '/^show_admin_login_once\(\)/,/^urls_and_optional_admin\(\)/' "$SCRIPT" | grep -q 'tee -a "$LOG"'; then
  echo 'FAIL: admin-login must not write the password to the log' >&2
  exit 1
fi

echo "[14/18] current script copies match"
cmp -s remnawave-manager.sh "$SCRIPT"

echo "[15/18] VERSION string"
grep -Fq "VERSION='1.5.1'" "$SCRIPT"
if grep -nE "^VERSION='[^']*-prod'" remnawave-manager.sh; then
  echo 'FAIL: current VERSION must not use a -prod suffix' >&2
  exit 1
fi

echo "[16/18] SHA256SUMS covers every versioned script"
missing=0
for f in remnawave-manager-v*.sh remnawave-manager.sh; do
  if ! grep -Fq "  $f" SHA256SUMS; then
    echo "missing checksum: $f" >&2
    missing=1
  fi
done
[[ $missing -eq 0 ]]

echo "[17/18] verify checksums"
sha256sum -c SHA256SUMS

echo "[18/18] dry-run repair help text"
grep -Fq repair /tmp/rw-help.txt
grep -Fq 'install node' /tmp/rw-help.txt

echo "STATIC AUDIT OK"
