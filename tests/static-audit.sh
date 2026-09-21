#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "[1/5] bash -n"
bash -n remnawave-manager-v25.1.4-prod.sh

echo "[2/5] help"
bash remnawave-manager-v25.1.4-prod.sh --help >/dev/null

echo "[3/5] dry-run single"
bash remnawave-manager-v25.1.4-prod.sh install single --dry-run --yes   DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com   DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null

echo "[4/5] dry-run panel + edge"
bash remnawave-manager-v25.1.4-prod.sh install panel --dry-run --yes   DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com   DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20   ADMIN_EMAIL=admin@example.com >/dev/null
bash remnawave-manager-v25.1.4-prod.sh install edge --dry-run --yes   PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com   ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret >/dev/null

echo "[5/5] checksums"
sha256sum -c SHA256SUMS

echo "STATIC AUDIT OK"
