#!/usr/bin/env bash
# Remnawave Manager — cabinet test harness.
# No payment-gateway SDKs, no Telegram/VK/Yandex app install, no Remnawave panel.
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PORT="${CABINET_PORT:-43291}"
HOST="${CABINET_HOST:-127.0.0.1}"
DATA="${CABINET_DATA:-$(mktemp -d /tmp/rw-cabinet-test.XXXXXX)}"
export CABINET_MODE=test
export CABINET_PORT="$PORT"
export CABINET_HOST="$HOST"
export CABINET_DATA="$DATA"
export CABINET_ADMIN_PASSWORD="${CABINET_ADMIN_PASSWORD:-corgi-test}"
export CABINET_SECRET="${CABINET_SECRET:-cabinet-test-secret}"
export DOMAIN_SUB="${DOMAIN_SUB:-sub.example.com}"
unset REMNAWAVE_TOKEN || true

cd "$ROOT"
python3 -m py_compile cabinet/server.py

echo "Corgi Lusi cabinet TEST"
echo "  user : http://${HOST}:${PORT}/"
echo "  admin: http://${HOST}:${PORT}/admin"
echo "  admin password: ${CABINET_ADMIN_PASSWORD}"
echo "  data : $DATA"
echo "  payments: off (mock, no gateways)"
echo "  oauth: mock Telegram / VK / Yandex"
echo
echo "Stop: Ctrl+C"
exec python3 cabinet/server.py --test --host "$HOST" --port "$PORT"
