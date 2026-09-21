#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SCRIPT=remnawave-manager-v25.1.14-prod.sh

echo "[1/14] bash -n current + historical"
bash -n "$SCRIPT"
bash -n remnawave-manager.sh
for f in remnawave-manager-v25.1.{0,1,2,3,4,5,6,7,8,9,10,11,12,13}-prod.sh; do
  bash -n "$f"
done

echo "[2/14] help"
bash "$SCRIPT" --help >/dev/null

echo "[3/14] dry-run single"
sudo bash "$SCRIPT" install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null

echo "[4/14] dry-run panel + edge"
sudo bash "$SCRIPT" install panel --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com >/dev/null
sudo bash "$SCRIPT" install edge --dry-run --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret >/dev/null

echo "[5/14] SSH port fallback"
grep -Fq 'ssh_ports()' "$SCRIPT"
grep -Fq 'ssh_port_list()' "$SCRIPT"
grep -Fq 'systemctl show ssh.socket' "$SCRIPT"
grep -Fq "ports='22'" "$SCRIPT"

echo "[6/14] Node is not created on 127.0.0.1"
if grep -n "create_node '127.0.0.1'" "$SCRIPT"; then
  echo 'FAIL: panel container cannot reach host loopback' >&2
  exit 1
fi
grep -Fq 'node_host_address()' "$SCRIPT"
grep -Fq 'docker_node_subnet()' "$SCRIPT"

echo "[7/14] Panel mode publishes HTTPS on 443"
awk '/^install_panel\(\)/,/^install_edge\(\)/' "$SCRIPT" | grep -Fq 'write_sni_router 0'
grep -Fq 'write_reject_vhost' "$SCRIPT"

echo "[8/14] Hysteria2 / Prometheus / Redis / restore / OS upgrade"
grep -Fq 'command: ["run","-c","/etc/sing-box/config.json"]' "$SCRIPT"
grep -Fq "host.docker.internal:9100" "$SCRIPT"
grep -Fq 'set_env REDIS_SOCKET /var/run/valkey/valkey.sock' "$SCRIPT"
grep -Fq '[[ "$archive" == *.age ]]' "$SCRIPT"
grep -Fq 'persist_manager' "$SCRIPT"
grep -Fq 'apt-get full-upgrade -y -qq' "$SCRIPT"
grep -Fq 'apt-get autoremove --purge -y -qq' "$SCRIPT"
grep -Fq '/var/run/reboot-required' "$SCRIPT"

echo "[9/14] nginx ProxyCheck headers + Corgi SelfSteal + repair"
grep -Fq 'snippets/remnawave-proxy.conf' "$SCRIPT"
grep -Fq 'X-Forwarded-Proto https' "$SCRIPT"
grep -Fq 'proxy_http_version 1.1' "$SCRIPT"
grep -Fq 'Corgi Lusi' "$SCRIPT"
grep -Fq "SELFSTEAL_TEMPLATE:-corgi" "$SCRIPT"
grep -Fq 'repair()' "$SCRIPT"
grep -Fq 'migrate_ssl_params_includes' "$SCRIPT"
grep -Fq 'NGINX_SKIP_RELOAD' "$SCRIPT"
grep -Fq 'Compatibility stub' "$SCRIPT"
if grep -n 'include /etc/nginx/proxy_params' "$SCRIPT"; then
  echo 'FAIL: Ubuntu proxy_params is not sufficient for ProxyCheckMiddleware' >&2
  exit 1
fi

echo "[10/14] current script copies match"
cmp -s remnawave-manager.sh "$SCRIPT"

echo "[11/14] VERSION string"
grep -Fq "VERSION='25.1.14-prod'" "$SCRIPT"

echo "[12/14] SHA256SUMS covers every versioned script"
missing=0
for f in remnawave-manager-v25.1.*.sh remnawave-manager.sh; do
  if ! grep -Fq "  $f" SHA256SUMS; then
    echo "missing checksum: $f" >&2
    missing=1
  fi
done
[[ $missing -eq 0 ]]

echo "[13/14] verify checksums"
sha256sum -c SHA256SUMS

echo "[14/14] dry-run repair help text"
bash "$SCRIPT" --help | grep -Fq repair

echo "STATIC AUDIT OK"
