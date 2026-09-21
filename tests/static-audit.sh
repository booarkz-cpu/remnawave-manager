#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "[1/6] bash -n"
bash -n remnawave-manager-25.1.10-prod.sh

echo "[2/6] help"
bash remnawave-manager-25.1.10-prod.sh --help >/dev/null

echo "[3/6] dry-run single"
sudo bash remnawave-manager-25.1.10-prod.sh install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null

echo "[4/6] dry-run panel + edge"
sudo bash remnawave-manager-25.1.10-prod.sh install panel --dry-run --yes \
  DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com >/dev/null
sudo bash remnawave-manager-25.1.10-prod.sh install edge --dry-run --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret >/dev/null

echo "[5/6] SSH port fallback code present"
grep -Fq 'ssh_ports()' remnawave-manager-25.1.10-prod.sh
grep -Fq 'systemctl show ssh.socket' remnawave-manager-25.1.10-prod.sh
grep -Fq "ports='22'" remnawave-manager-25.1.10-prod.sh

echo "[6/6] current checksum"
grep -F "  remnawave-manager-25.1.10-prod.sh" SHA256SUMS | sha256sum -c -

echo "[6/7] OS full upgrade code"
grep -Fq 'apt-get full-upgrade -y -qq' remnawave-manager-v25.1.10-prod.sh
grep -Fq 'apt-get autoremove --purge -y -qq' remnawave-manager-v25.1.10-prod.sh
grep -Fq 'apt-get autoclean -qq' remnawave-manager-v25.1.10-prod.sh
grep -Fq '/var/run/reboot-required' remnawave-manager-v25.1.10-prod.sh
echo "STATIC AUDIT OK"
