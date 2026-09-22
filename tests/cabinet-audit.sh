#!/usr/bin/env bash
# API audit of the cabinet test server (no payment gateways).
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PORT="${CABINET_PORT:-43292}"
DATA="$(mktemp -d /tmp/rw-cab-audit.XXXXXX)"
export CABINET_MODE=test CABINET_DATA="$DATA" CABINET_ADMIN_PASSWORD=corgi-test CABINET_SECRET=audit-secret
python3 -m py_compile cabinet/server.py
python3 cabinet/server.py --test --host 127.0.0.1 --port "$PORT" >"$DATA/server.log" 2>&1 &
pid=$!
cleanup(){ kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; rm -rf "$DATA"; }
trap cleanup EXIT
ok=0
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null 2>&1; then ok=1; break; fi
  sleep 0.1
done
[[ $ok -eq 1 ]]

curl -fsS "http://127.0.0.1:${PORT}/api/health" | grep -Fq '"mode":"test"'
curl -fsS "http://127.0.0.1:${PORT}/api/health" | grep -Fq '"payments":"none"'
curl -fsS "http://127.0.0.1:${PORT}/" | grep -Fq 'Corgi Lusi'
curl -fsS "http://127.0.0.1:${PORT}/admin" | grep -Fq 'Админ'
curl -fsS "http://127.0.0.1:${PORT}/static/app.css" | grep -Fq -- '--md-sys-color-primary'
curl -fsS "http://127.0.0.1:${PORT}/api/public/config" | grep -Fq '"mock_payments":true'
curl -fsS "http://127.0.0.1:${PORT}/api/tariffs" | grep -Fq trial

cj="$DATA/cookies.txt"
aj="$DATA/admin.txt"
email="user$(date +%s)@example.com"
curl -fsS -c "$cj" -b "$cj" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"correcthorse\",\"name\":\"Test\"}" \
  "http://127.0.0.1:${PORT}/api/auth/register" | grep -Fq '"has_subscription":false'

curl -fsS -c "$cj" -b "$cj" -H 'Content-Type: application/json' \
  -d '{"email":"'"$email"'","password":"wrongwrong"}' \
  "http://127.0.0.1:${PORT}/api/auth/login" && { echo 'FAIL: bad password accepted' >&2; exit 1; } || true

tid="$(python3 - <<PY
import json,urllib.request
print(json.load(urllib.request.urlopen('http://127.0.0.1:${PORT}/api/tariffs'))['tariffs'][0]['id'])
PY
)"
curl -fsS -c "$cj" -b "$cj" -H 'Content-Type: application/json' \
  -d "{\"tariff_id\":$tid}" \
  "http://127.0.0.1:${PORT}/api/trial" | grep -Fq subscriptionUrl

curl -fsS -c "$cj" -b "$cj" "http://127.0.0.1:${PORT}/api/subscription" | grep -Fq '"has":true'
curl -fsS "http://127.0.0.1:${PORT}/api/instructions" | grep -Fq android

# mock oauth (no VK/Yandex/Telegram apps)
curl -fsS -D - -o /dev/null -c "$DATA/tg.txt" "http://127.0.0.1:${PORT}/api/auth/mock/telegram" | grep -Fq 'Set-Cookie: lk_sid='

curl -fsS -c "$aj" -b "$aj" -H 'Content-Type: application/json' \
  -d '{"password":"corgi-test"}' "http://127.0.0.1:${PORT}/api/admin/login" | grep -Fq '"admin":true'
curl -fsS -c "$aj" -b "$aj" "http://127.0.0.1:${PORT}/api/admin/settings" | grep -Fq brand
if curl -fsS -c "$aj" -b "$aj" "http://127.0.0.1:${PORT}/api/admin/settings" | grep -q '"tg_bot_token"'; then
  echo 'FAIL: admin settings leaked tg_bot_token' >&2
  exit 1
fi

curl -fsS -c "$aj" -b "$aj" -H 'Content-Type: application/json' \
  -d '{"slug":"faq","title_ru":"Вопросы","title_en":"FAQ","kind":"page","sort":90,"body":"<p>ok</p>","enabled":1}' \
  "http://127.0.0.1:${PORT}/api/admin/menu" | grep -Fq '"ok":true'
curl -fsS "http://127.0.0.1:${PORT}/api/menu" | grep -Fq faq
curl -fsS "http://127.0.0.1:${PORT}/api/pages/faq" | grep -Fq '<p>ok</p>'

curl -fsS -c "$aj" -b "$aj" -H 'Content-Type: application/json' \
  -d '{"slug":"vip","title_ru":"VIP","title_en":"VIP","days":60,"traffic_gb":200,"devices":3,"price_rub":700,"sort":55}' \
  "http://127.0.0.1:${PORT}/api/admin/tariffs" | grep -Fq '"ok":true'

# XSS in menu body stripped
curl -fsS -c "$aj" -b "$aj" -H 'Content-Type: application/json' \
  -d '{"slug":"xss","title_ru":"x","title_en":"x","kind":"page","body":"<script>alert(1)</script><p>safe</p>"}' \
  "http://127.0.0.1:${PORT}/api/admin/menu" >/dev/null
curl -fsS "http://127.0.0.1:${PORT}/api/pages/xss" | grep -Fq safe
if curl -fsS "http://127.0.0.1:${PORT}/api/pages/xss" | grep -q '<script'; then echo 'FAIL: script not sanitized' >&2; exit 1; fi

python3 - <<PY > "$DATA/xss2.json"
import json
print(json.dumps({
    "slug": "xss2",
    "title_ru": "<b>bad</b>",
    "title_en": "x",
    "kind": "page",
    "body": '<img src=x onerror=alert(1)><a href="javascript:alert(1)">x</a><p>ok2</p>',
}))
PY
curl -fsS -c "$aj" -b "$aj" -H 'Content-Type: application/json' -d @"$DATA/xss2.json" \
  "http://127.0.0.1:${PORT}/api/admin/menu" >/dev/null
page="$(curl -fsS "http://127.0.0.1:${PORT}/api/pages/xss2")"
echo "$page" | grep -Fq ok2
if echo "$page" | grep -qi onerror; then echo 'FAIL: onerror survived' >&2; exit 1; fi
if echo "$page" | grep -qi javascript:; then echo 'FAIL: javascript: survived' >&2; exit 1; fi
if echo "$page" | grep -Fq '<b>bad</b>'; then echo 'FAIL: title tags not stripped' >&2; exit 1; fi

# edit existing menu tab
curl -fsS -c "$aj" -b "$aj" -H 'Content-Type: application/json' \
  -d '{"slug":"faq","title_ru":"FAQ2","title_en":"FAQ2","kind":"page","sort":91}' \
  "http://127.0.0.1:${PORT}/api/admin/menu" | grep -Fq '"ok":true'
curl -fsS "http://127.0.0.1:${PORT}/api/menu" | grep -Fq FAQ2

# bad checkout id must not 500
code="$(curl -sS -o /dev/null -w '%{http_code}' -c "$cj" -b "$cj" -H 'Content-Type: application/json' \
  -d '{}' "http://127.0.0.1:${PORT}/api/orders/nope/checkout")"
[[ "$code" == 400 ]]

# telegram widget callback in test skips OAuth state (mock)
curl -fsS -D - -o /dev/null -c "$DATA/tg2.txt" \
  "http://127.0.0.1:${PORT}/api/auth/telegram/callback?hash=x" | grep -Fq 'Set-Cookie: lk_sid='

# deleting a used tariff disables instead of 500
paid_tid="$(python3 - <<PY
import json,urllib.request
print(json.load(urllib.request.urlopen('http://127.0.0.1:${PORT}/api/tariffs'))['tariffs'][1]['id'])
PY
)"
curl -fsS -c "$cj" -b "$cj" -H 'Content-Type: application/json' \
  -d "{\"tariff_id\":$paid_tid}" "http://127.0.0.1:${PORT}/api/orders" >/dev/null
curl -fsS -c "$aj" -b "$aj" -X DELETE "http://127.0.0.1:${PORT}/api/admin/tariffs/${paid_tid}" | grep -Fq '"ok":true'

echo "CABINET AUDIT OK"
