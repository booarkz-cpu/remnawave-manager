#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SCRIPT=remnawave-manager-v25.2.0-prod.sh

echo "[1/16] bash -n current + historical"
bash -n "$SCRIPT"
bash -n remnawave-manager.sh
for f in remnawave-manager-v25.1.{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}-prod.sh; do
  bash -n "$f"
done

echo "[2/16] help"
bash "$SCRIPT" --help >/dev/null
bash "$SCRIPT" --help | grep -Fq 'rezzosoft.ru/converter.html'

echo "[3/16] dry-run single"
sudo bash "$SCRIPT" install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null

echo "[4/16] dry-run panel + node"
sudo bash "$SCRIPT" install panel --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com >/dev/null
sudo bash "$SCRIPT" install node --dry-run --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret --grpc --xhttp --hysteria2 >/dev/null

echo "[5/16] SSH port fallback"
grep -Fq 'ssh_ports()' "$SCRIPT"
grep -Fq 'ssh_port_list()' "$SCRIPT"
grep -Fq 'systemctl show ssh.socket' "$SCRIPT"
grep -Fq "ports='22'" "$SCRIPT"

echo "[6/16] Node is not created on 127.0.0.1"
if grep -n "create_node '127.0.0.1'" "$SCRIPT"; then
  echo 'FAIL: panel container cannot reach host loopback' >&2
  exit 1
fi
grep -Fq 'node_host_address()' "$SCRIPT"
grep -Fq 'docker_node_subnet()' "$SCRIPT"

echo "[7/16] Panel mode publishes HTTPS on 443"
awk '/^install_panel\(\)/,/^install_edge\(\)/' "$SCRIPT" | grep -Fq 'write_sni_router 0'
grep -Fq 'write_reject_vhost' "$SCRIPT"

echo "[8/16] Hysteria2 / Prometheus / Redis / restore / OS upgrade"
grep -Fq 'command: ["run","-c","/etc/sing-box/config.json"]' "$SCRIPT"
grep -Fq "host.docker.internal:9100" "$SCRIPT"
grep -Fq 'set_env REDIS_SOCKET /var/run/valkey/valkey.sock' "$SCRIPT"
grep -Fq '[[ "$archive" == *.age ]]' "$SCRIPT"
grep -Fq 'persist_manager' "$SCRIPT"
grep -Fq 'apt-get full-upgrade -y -qq' "$SCRIPT"
grep -Fq 'apt-get autoremove --purge -y -qq' "$SCRIPT"
grep -Fq '/var/run/reboot-required' "$SCRIPT"

echo "[9/16] nginx ProxyCheck headers + Corgi SelfSteal + repair"
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

echo "[10/16] subscription-page token check + empty CUSTOM_SUB_PREFIX"
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

echo "[11/16] Rezzosoft / gRPC / xHTTP / menu / credits"
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

echo "[12/16] current script copies match"
cmp -s remnawave-manager.sh "$SCRIPT"

echo "[13/16] VERSION string"
grep -Fq "VERSION='25.2.0-prod'" "$SCRIPT"

echo "[14/16] SHA256SUMS covers every versioned script"
missing=0
for f in remnawave-manager-v25*.sh remnawave-manager.sh; do
  if ! grep -Fq "  $f" SHA256SUMS; then
    echo "missing checksum: $f" >&2
    missing=1
  fi
done
[[ $missing -eq 0 ]]

echo "[15/16] verify checksums"
sha256sum -c SHA256SUMS

echo "[16/16] dry-run repair help text"
bash "$SCRIPT" --help | grep -Fq repair
bash "$SCRIPT" --help | grep -Fq 'install node'

echo "STATIC AUDIT OK"
