#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash -n remnawave-manager-v25.1.2-prod.sh
bash remnawave-manager-v25.1.2-prod.sh --help >/dev/null

run_dry() {
  sudo bash remnawave-manager-v25.1.2-prod.sh install "$@"
}

run_dry single --dry-run --yes DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com >/dev/null
run_dry panel --dry-run --yes DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 ADMIN_EMAIL=admin@example.com >/dev/null
run_dry edge --dry-run --yes PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY=testsecret >/dev/null

sha256sum -c SHA256SUMS
echo "STATIC AUDIT OK"

