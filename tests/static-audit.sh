#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SCRIPT=remnawave-manager-v25.1.11-prod.sh

echo "[1/12] bash -n current + historical"
bash -n "$SCRIPT"
bash -n remnawave-manager.sh
for f in remnawave-manager-v25.1.{0,1,2,3,4,5,6,7,8,9,10}-prod.sh; do
  bash -n "$f"
done

echo "[2/12] help"
bash "$SCRIPT" --help >/dev/null

echo "[3/12] dry-run single"
sudo bash "$SCRIPT" install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null

echo "[4/12] dry-run panel + edge"
sudo bash "$SCRIPT" install panel --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com >/dev/null
sudo bash "$SCRIPT" install edge --dry-run --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret >/dev/null

echo "[5/12] SSH port fallback"
grep -Fq 'ssh_ports()' "$SCRIPT"
grep -Fq 'systemctl show ssh.socket' "$SCRIPT"
grep -Fq "ports='22'" "$SCRIPT"

echo "[6/12] Node is not created on 127.0.0.1"
if grep -n "create_node '127.0.0.1'" "$SCRIPT"; then
  echo 'FAIL: panel container cannot reach host loopback' >&2
  exit 1
fi
grep -Fq 'node_host_address()' "$SCRIPT"
grep -Fq 'docker_node_subnet()' "$SCRIPT"

echo "[7/12] Panel mode publishes HTTPS on 443"
awk '/^install_panel\(\)/,/^install_edge\(\)/' "$SCRIPT" | grep -Fq 'write_sni_router 0'
grep -Fq 'write_reject_vhost' "$SCRIPT"

echo "[8/12] Hysteria2 / Prometheus / Redis / restore / OS upgrade"
grep -Fq 'command: ["run","-c","/etc/sing-box/config.json"]' "$SCRIPT"
grep -Fq "host.docker.internal:9100" "$SCRIPT"
grep -Fq 'set_env REDIS_SOCKET /var/run/valkey/valkey.sock' "$SCRIPT"
grep -Fq '[[ "$archive" == *.age ]]' "$SCRIPT"
grep -Fq 'persist_manager' "$SCRIPT"
grep -Fq 'apt-get full-upgrade -y -qq' "$SCRIPT"
grep -Fq 'apt-get autoremove --purge -y -qq' "$SCRIPT"
grep -Fq '/var/run/reboot-required' "$SCRIPT"

echo "[9/12] current script copies match"
cmp -s remnawave-manager.sh "$SCRIPT"

echo "[10/12] VERSION string"
grep -Fq "VERSION='25.1.11-prod'" "$SCRIPT"

echo "[11/12] SHA256SUMS covers every versioned script"
missing=0
for f in remnawave-manager-v25.1.*.sh remnawave-manager.sh; do
  if ! grep -Fq "  $f" SHA256SUMS; then
    echo "missing checksum: $f" >&2
    missing=1
  fi
done
[[ $missing -eq 0 ]]

echo "[12/12] verify checksums"
sha256sum -c SHA256SUMS

echo "STATIC AUDIT OK"
