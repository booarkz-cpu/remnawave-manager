#!/usr/bin/env bash
# ==============================================================================
# Remnawave Manager v25.1.0-prod
# Полностью автоматизированный production-установщик Remnawave.
#
# Основные цели v25:
#   - актуальный официальный backend compose + .env.sample;
#   - автоматический bootstrap super-admin -> JWT -> API token;
#   - автоматическое создание X25519, Config Profile, VLESS REALITY inbound;
#   - автоматическое создание Node и привязка профиля;
#   - Single-VDS и Multi-VDS Panel/Edge;
#   - Nginx SNI routing TCP/443 без прямого доступа к backend-портам;
#   - Let's Encrypt webroot + ECDSA;
#   - UFW, fail2ban, unattended-upgrades, Docker log rotation;
#   - healthcheck/API check, backup, restore, certificate renewal;
#   - опциональные Hysteria2, Prometheus/node-exporter/cAdvisor;
#   - безопасный dry-run и идемпотентный повторный запуск;
#   - shellcheck-friendly Bash.
#
# Важно:
#   Hysteria2/sing-box не является inbound'ом Xray Config Profile Remnawave.
#   Он устанавливается отдельно и не маскируется как часть Xray profile.
# ===============================================================================
set -Eeuo pipefail
IFS=$'\n\t'

VERSION='25.1.2-prod'
BASE='/opt/remnawave'
EDGE_BASE='/opt/remnawave-edge'
BACKUP_BASE='/var/backups/remnawave'
LOG='/var/log/remnawave-manager.log'
ENV_FILE="$BASE/manager.env"
EDGE_ENV="$EDGE_BASE/manager.env"
BOOTSTRAP_FILE="$BASE/bootstrap.env"
CREDS_FILE="$BASE/credentials.txt"
API_LOCAL='http://127.0.0.1:3000/api'
STREAM_CONF='/etc/nginx/stream.conf'
AUTO_YES=0
DRY_RUN=0
MONITORING=0
HYSTERIA2=0
TELEGRAM_ALERTS=0
BBR=1
DISABLE_IPV6=0
SELFSTEAL=0
XCORE_SOURCE='builtin'
ADMIN_IP=''

# Load persistent manager state before CLI parsing; explicit KEY=VALUE args override it.
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE" || true
  set +a
fi

if [[ -t 1 ]]; then
  C_GREEN='\033[32m'; C_RED='\033[31m'; C_YELLOW='\033[33m'
  C_BLUE='\033[34m'; C_CYAN='\033[36m'; C_BOLD='\033[1m'; C_RESET='\033[0m'
else
  C_GREEN=''; C_RED=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_BOLD=''; C_RESET=''
fi

log(){ mkdir -p "$(dirname "$LOG")"; echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }
ok(){ log "${C_GREEN}✓${C_RESET} $*"; }
warn(){ log "${C_YELLOW}⚠${C_RESET} $*"; }
die(){ log "${C_RED}✗${C_RESET} $*"; exit 1; }
trap 'rc=$?; die "Ошибка в строке $LINENO (код $rc). Смотрите $LOG"' ERR

require_root(){ [[ $EUID -eq 0 ]] || die 'Запустите скрипт от root.'; }
rand(){ local n="${1:-32}"; openssl rand -hex "$(( (n + 1) / 2 ))" | cut -c1-"$n"; }

validate_domain(){ [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]]; }
validate_email(){ [[ "$1" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; }
validate_ip(){ [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && awk -F. '{for(i=1;i<=4;i++) if($i>255) exit 1}' <<<"$1"; }
public_ip(){ curl -4fsS --max-time 8 https://api.ipify.org || true; }
ssh_port(){ sshd -T 2>/dev/null | awk '$1=="port"{print $2; exit}' || echo 22; }

run(){
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s\n' "[DRY-RUN] $*"
    return 0
  fi
  "$@"
}

ask(){
  local var="$1" prompt="$2" default="${3:-}" validator="${4:-}" val
  if [[ -n "${!var:-}" ]]; then val="${!var}"; else
    if [[ $AUTO_YES -eq 1 ]]; then
      [[ -n "$default" ]] || die "--yes требует параметр $var."
      val="$default"
    elif [[ -n "$default" ]]; then
      read -r -p "${C_CYAN}?${C_RESET} $prompt [$default]: " val; val="${val:-$default}"
    else
      while :; do read -r -p "${C_CYAN}?${C_RESET} $prompt: " val; [[ -n "$val" ]] && break; done
    fi
  fi
  if [[ -n "$validator" ]]; then
    "$validator" "$val" || die "Некорректное значение для $var: $val"
  fi
  printf -v "$var" '%s' "$val"
}

check_os(){
  [[ -r /etc/os-release ]] || die 'Не найден /etc/os-release.'
  # Поддерживаем Debian/Ubuntu; на иных системах намеренно останавливаемся.
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in ubuntu|debian) ;; *) die "Поддерживаются Ubuntu/Debian, обнаружено: ${ID:-unknown}";; esac
}

install_base(){
  export DEBIAN_FRONTEND=noninteractive
  check_os
  log 'Устанавливаем системные зависимости...'
  if [[ $DRY_RUN -eq 1 ]]; then
    log '[DRY-RUN] apt-get update/install, Docker, nginx, certbot, UFW, fail2ban, rclone, age'
    return 0
  fi
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl wget jq openssl nginx certbot ufw unzip socat python3 \
    libnginx-mod-stream fail2ban unattended-upgrades rclone age file logrotate
  if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; fi
  systemctl enable --now docker nginx fail2ban >/dev/null 2>&1 || true
  docker compose version >/dev/null 2>&1 || die 'Docker Compose plugin не найден.'
  nginx -V 2>&1 | grep -q 'stream' || warn 'Проверка stream-модуля через nginx -V не дала результата; проверим nginx -t после загрузки модуля.'
  ok 'Базовые пакеты установлены.'
}

configure_security(){
  local p; p="$(ssh_port)"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[DRY-RUN] fail2ban SSH порт $p, unattended-upgrades, Docker log rotation, UFW"
    return 0
  fi
  cat > /etc/fail2ban/jail.local <<EOF2
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = $p
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600
EOF2
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF2'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF2
  cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF2'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}";
  "${distro_id}:${distro_codename}-security";
  "${distro_id}ESMApps:${distro_codename}-apps-security";
  "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF2
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'EOF2'
{
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"}
}
EOF2
  cat > /etc/logrotate.d/remnawave-manager <<'EOF2'
/var/log/remnawave-manager.log {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  create 0600 root root
}
EOF2
  systemctl restart docker
  systemctl enable --now unattended-upgrades fail2ban >/dev/null 2>&1 || true
  ok 'SSH/fail2ban/unattended-upgrades/Docker log rotation настроены.'
}

write_firewall(){
  local mode="$1" p; p="$(ssh_port)"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[DRY-RUN] UFW: SSH $p, 80/tcp, 443/tcp; Edge: 8443/udp (если включена Hysteria2); Node API 2222 только с Panel"
    return 0
  fi
  ufw default deny incoming >/dev/null
  ufw default allow outgoing >/dev/null
  ufw allow "$p/tcp" >/dev/null
  ufw allow 80/tcp >/dev/null
  ufw allow 443/tcp >/dev/null
  if [[ "$mode" == edge || "$mode" == single ]]; then
    [[ $HYSTERIA2 -eq 1 ]] && ufw allow 8443/udp >/dev/null || true
  fi
  if [[ "$mode" == edge ]]; then
    validate_ip "${PANEL_IP:-}" || die 'PANEL_IP некорректен.'
    ufw allow from "$PANEL_IP" to any port 2222 proto tcp >/dev/null
  fi
  # Docker-сеть не должна случайно открывать host-порты наружу.
  ufw --force enable >/dev/null
  ok 'UFW включён.'
}

write_panel_env(){
  mkdir -p "$BASE"
  cd "$BASE"
  local pgpass appsecret webhooksecret metrics_pass
  if [[ ! -f .env ]]; then
    curl -fsSL https://raw.githubusercontent.com/remnawave/backend/main/.env.sample -o .env.sample
    cp .env.sample .env
  fi
  pgpass="${POSTGRES_PASSWORD:-$(grep '^POSTGRES_PASSWORD=' .env | cut -d= -f2- || true)}"
  [[ -n "$pgpass" && "$pgpass" != postgres && "$pgpass" != change_me ]] || pgpass="$(rand 40)"
  appsecret="${APP_SECRET:-$(grep '^APP_SECRET=' .env | cut -d= -f2- || true)}"
  [[ -n "$appsecret" && "$appsecret" != change_me ]] || appsecret="$(rand 128)"
  webhooksecret="${WEBHOOK_SECRET_HEADER:-$(grep '^WEBHOOK_SECRET_HEADER=' .env | cut -d= -f2- || true)}"
  [[ ${#webhooksecret} -eq 64 ]] || webhooksecret="$(rand 64)"
  metrics_pass="${METRICS_PASS:-$(grep '^METRICS_PASS=' .env | cut -d= -f2- || true)}"
  [[ -n "$metrics_pass" && "$metrics_pass" != admin ]] || metrics_pass="$(rand 32)"

  set_env(){
    local key="$1" value="$2"
    if grep -q "^${key}=" .env; then
      sed -i "s|^${key}=.*|${key}=${value}|" .env
    else
      printf '%s=%s\n' "$key" "$value" >> .env
    fi
  }
  set_env APP_PORT 3000
  set_env METRICS_PORT 3001
  set_env API_INSTANCES 1
  set_env APP_SECRET "$appsecret"
  set_env DATABASE_URL "\"postgresql://postgres:${pgpass}@remnawave-db:5432/postgres\""
  set_env PANEL_DOMAIN "$DOMAIN_PANEL"
  set_env FRONT_END_DOMAIN "${DOMAIN_PANEL}"
  set_env SUB_PUBLIC_DOMAIN "${DOMAIN_SUB}/sub"
  set_env METRICS_USER admin
  set_env METRICS_PASS "$metrics_pass"
  set_env WEBHOOK_SECRET_HEADER "$webhooksecret"
  set_env IS_TELEGRAM_NOTIFICATIONS_ENABLED false
  set_env WEBHOOK_ENABLED false
  set_env POSTGRES_USER postgres
  set_env POSTGRES_PASSWORD "$pgpass"
  set_env POSTGRES_DB postgres
  chmod 600 .env
  cat > "$ENV_FILE" <<EOF2
MODE=${MODE:-single}
DOMAIN_PANEL=${DOMAIN_PANEL:-}
DOMAIN_SUB=${DOMAIN_SUB:-}
DOMAIN_REALITY=${DOMAIN_REALITY:-}
DOMAIN_NODE=${DOMAIN_NODE:-}
EDGE_ADDRESS=${EDGE_ADDRESS:-}
ADMIN_EMAIL=${ADMIN_EMAIL:-}
ADMIN_USERNAME=${ADMIN_USERNAME:-}
POSTGRES_PASSWORD=$pgpass
METRICS_PASS=$metrics_pass
API_TOKEN=${API_TOKEN:-}
SUB_API_TOKEN=${SUB_API_TOKEN:-}
NODE_SECRET_KEY=${NODE_SECRET_KEY:-}
EOF2
  chmod 600 "$ENV_FILE"
}

install_panel_compose(){
  cd "$BASE"
  curl -fsSL https://raw.githubusercontent.com/remnawave/backend/main/docker-compose-prod.yml -o docker-compose.yml
  docker compose config >/dev/null
  docker compose pull -q
  docker compose up -d --wait --wait-timeout 180
}

api_call(){
  local method="$1" path="$2" body="${3:-}" token="${4:-}"
  local args=(-sS --max-time 30 -X "$method" -H 'Content-Type: application/json' -H 'Accept: application/json')
  [[ -n "$token" ]] && args+=( -H "Authorization: Bearer $token" )
  [[ -n "$body" ]] && args+=( --data "$body" )
  curl "${args[@]}" -w '\n%{http_code}' "${API_LOCAL}${path}"
}
api_json(){
  local raw code json; raw="$1"; code="$(tail -n1 <<<"$raw")"; json="$(sed '$d' <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || die "API HTTP $code: $json"
  jq -e . >/dev/null <<<"$json" || die "API вернул не-JSON: $json"
  printf '%s' "$json"
}
wait_api(){
  for _ in {1..90}; do
    curl -fsS --max-time 2 "$API_LOCAL/auth/status" >/dev/null 2>&1 && return 0
    sleep 2
  done
  die 'Remnawave API не отвечает.'
}

bootstrap_auth(){
  if [[ -n "${API_TOKEN:-}" ]]; then
    if api_json "$(api_call GET /config-profiles '' "$API_TOKEN")" >/dev/null 2>&1; then
      API_JWT="${API_JWT:-$API_TOKEN}"
      ok 'Используем сохранённый API token.'
      return 0
    fi
  fi
  local status reg
  status="$(api_json "$(api_call GET /auth/status)")"
  reg="$(jq -r '.response.isRegisterAllowed // false' <<<"$status")"
  if [[ "$reg" == true ]]; then
    log 'Регистрируем первого администратора.'
    API_JWT="$(api_json "$(api_call POST /auth/register "$(jq -nc --arg u "$ADMIN_USERNAME" --arg p "$ADMIN_PASSWORD" '{username:$u,password:$p}')")" | jq -r '.response.accessToken')"
  else
    log 'Регистрация уже закрыта; выполняем login существующего администратора.'
    API_JWT="$(api_json "$(api_call POST /auth/login "$(jq -nc --arg u "$ADMIN_USERNAME" --arg p "$ADMIN_PASSWORD" '{username:$u,password:$p}')")" | jq -r '.response.accessToken')"
  fi
  [[ -n "$API_JWT" && "$API_JWT" != null ]] || die 'JWT администратора не получен.'
  local t
  t="$(api_json "$(api_call POST /tokens "$(jq -nc --arg n "remnawave-manager-$VERSION" '{name:$n,expiresInDays:3650,scopes:["*"]}')" "$API_JWT")")"
  API_TOKEN="$(jq -r '.response.token // empty' <<<"$t")"
  [[ -n "$API_TOKEN" ]] || die 'API Token не получен.'
  echo "API_TOKEN=$API_TOKEN" >> "$ENV_FILE"
  chmod 600 "$ENV_FILE"
}

get_node_secret(){
  if [[ -n "${NODE_SECRET_KEY:-}" ]]; then
    ok 'Используем переданный SECRET_KEY Node.'
    return 0
  fi
  local j secret
  j="$(api_json "$(api_call GET /keygen '' "$API_JWT")")"
  secret="$(jq -r '.response.secretKey // empty' <<<"$j")"
  [[ -n "$secret" ]] || die 'GET /api/keygen не вернул Node SECRET_KEY.'
  NODE_SECRET_KEY="$secret"
  ok 'Node SECRET_KEY получен через официальный API /api/keygen.'
}

create_subscription_token(){
  if [[ -n "${SUB_API_TOKEN:-}" ]]; then
    return 0
  fi
  local body result
  body="$(jq -nc --arg n "subscription-page-$VERSION" '{name:$n,expiresInDays:3650,scopes:["subscription-page-configs:list","subscription-page-configs:get","subscriptions:subpage-config","system:metadata","users:by-username"]}')"
  result="$(api_json "$(api_call POST /tokens "$body" "$API_JWT")")"
  SUB_API_TOKEN="$(jq -r '.response.token // empty' <<<"$result")"
  [[ -n "$SUB_API_TOKEN" ]] || die 'Минимальный API token для Subscription Page не получен.'
}

generate_x25519(){
  local j
  j="$(api_json "$(api_call GET /system/tools/x25519/generate '' "$API_JWT")" 2>/dev/null || true)"
  if [[ -n "$j" ]]; then
    REALITY_PRIVATE_KEY="$(jq -r '.response.keypairs[0].privateKey // empty' <<<"$j")"
    REALITY_PUBLIC_KEY="$(jq -r '.response.keypairs[0].publicKey // empty' <<<"$j")"
  fi
  [[ -n "${REALITY_PRIVATE_KEY:-}" && -n "${REALITY_PUBLIC_KEY:-}" ]] || die 'API X25519 недоступен: автоматический Reality bootstrap остановлен.'
}

create_config_profile(){
  REALITY_SHORT_ID="$(rand 16)"
  local target='127.0.0.1:9450' existing profile
  existing="$(api_json "$(api_call GET /config-profiles '' "$API_JWT")")"
  PROFILE_UUID="$(jq -r '.response.configProfiles[]? | select(.name=="AUTO-PROFILE") | .uuid' <<<"$existing" | head -1)"
  if [[ -n "$PROFILE_UUID" ]]; then
    INBOUND_UUID="$(jq -r --arg p "$PROFILE_UUID" '.response.configProfiles[]? | select(.uuid==$p) | .inbounds[0].uuid' <<<"$existing" | head -1)"
    [[ -n "$INBOUND_UUID" ]] || die 'AUTO-PROFILE существует, но inbound не найден.'
    return 0
  fi
  profile="$(jq -n --arg target "$target" --arg sni "$DOMAIN_REALITY" --arg pk "$REALITY_PRIVATE_KEY" --arg sid "$REALITY_SHORT_ID" '{log:{loglevel:"warning"},inbounds:[{tag:"VLESS_REALITY",port:8444,listen:"0.0.0.0",protocol:"vless",settings:{clients:[],decryption:"none"},sniffing:{enabled:true,destOverride:["http","tls","quic"],routeOnly:false},streamSettings:{network:"raw",security:"reality",realitySettings:{show:false,target:$target,xver:0,serverNames:[$sni],privateKey:$pk,minClientVer:"0.0.0",shortIds:[$sid]}}}],outbounds:[{protocol:"freedom",tag:"DIRECT"},{protocol:"blackhole",tag:"BLOCK"}],routing:{domainStrategy:"IPIfNonMatch",rules:[{ip:["geoip:private"],outboundTag:"BLOCK"},{domain:["geosite:private"],outboundTag:"BLOCK"},{protocol:["bittorrent"],outboundTag:"BLOCK"}]}}')"
  local created; created="$(api_json "$(api_call POST /config-profiles "$(jq -nc --arg n AUTO-PROFILE --argjson c "$profile" '{name:$n,config:$c}')" "$API_JWT")")"
  PROFILE_UUID="$(jq -r '.response.uuid // empty' <<<"$created")"
  INBOUND_UUID="$(jq -r '.response.inbounds[0].uuid // empty' <<<"$created")"
  [[ -n "$PROFILE_UUID" && -n "$INBOUND_UUID" ]] || die 'Config Profile/inbound UUID не получены.'
}

create_node(){
  local address="$1" name="$2" existing body node
  existing="$(api_json "$(api_call GET /nodes '' "$API_JWT")")"
  NODE_UUID="$(jq -r --arg n "$name" '.response[]? | select(.name==$n) | .uuid' <<<"$existing" | head -1)"
  if [[ -n "$NODE_UUID" ]]; then return 0; fi
  local plugin_uuid="" plugin_raw=""
  plugin_raw="$(api_call GET "/node-plugins?_=$(date +%s)" "" "$API_JWT" 2>/dev/null || true)"
  plugin_uuid="$(sed '$d' <<<"$plugin_raw" | jq -r '[.response[]?, .response.nodePlugins[]?] | map(select(.name=="Reverse Node Plugins" or ((.pluginConfig // {}) | has("torrentBlocker")))) | .[0].uuid // empty' 2>/dev/null || true)"
  if [[ -n "$plugin_uuid" ]]; then
    body="$(jq -nc --arg n "$name" --arg a "$address" --arg p "$PROFILE_UUID" --arg i "$INBOUND_UUID" --arg pl "$plugin_uuid" '{name:$n,address:$a,port:2222,countryCode:"XX",configProfile:{activeConfigProfileUuid:$p,activeInbounds:[$i]},activePluginUuid:$pl,isTrafficTrackingActive:false,trafficLimitBytes:0,notifyPercent:0,trafficResetDay:31,consumptionMultiplier:1.0}')"
  else
    body="$(jq -nc --arg n "$name" --arg a "$address" --arg p "$PROFILE_UUID" --arg i "$INBOUND_UUID" '{name:$n,address:$a,port:2222,countryCode:"XX",configProfile:{activeConfigProfileUuid:$p,activeInbounds:[$i]},isTrafficTrackingActive:false,trafficLimitBytes:0,notifyPercent:0,trafficResetDay:31,consumptionMultiplier:1.0}')"
  fi
  node="$(api_json "$(api_call POST /nodes "$body" "$API_JWT")")"
  NODE_UUID="$(jq -r '.response.uuid // empty' <<<"$node")"
  [[ -n "$NODE_UUID" ]] || die 'Node не создан.'
}

create_host(){
  local address="$1" existing body host
  existing="$(api_json "$(api_call GET /hosts '' "$API_JWT")")"
  HOST_UUID="$(jq -r --arg a "$address" --arg s "$DOMAIN_REALITY" --arg cp "$PROFILE_UUID" --arg ib "$INBOUND_UUID" \
    '.response[]? | select(.remark=="VLESS Reality" and .address==$a and .sni==$s and .inbound.configProfileUuid==$cp and .inbound.configProfileInboundUuid==$ib) | .uuid' <<<"$existing" | head -1)"
  [[ -n "$HOST_UUID" ]] && return 0
  body="$(jq -nc --arg cp "$PROFILE_UUID" --arg ib "$INBOUND_UUID" --arg a "$address" --arg s "$DOMAIN_REALITY" '{inbound:{configProfileUuid:$cp,configProfileInboundUuid:$ib},remark:"VLESS Reality",address:$a,port:443,sni:$s,fingerprint:"chrome",securityLayer:"DEFAULT",isDisabled:false,isHidden:false,allowInsecure:false}')"
  host="$(api_json "$(api_call POST /hosts "$body" "$API_JWT")")"
  HOST_UUID="$(jq -r '.response.uuid // empty' <<<"$host")"
  [[ -n "$HOST_UUID" ]] || die 'Host не создан.'
}

write_node_compose(){
  local root="$1" secret="$2"; mkdir -p "$root"
  cat > "$root/.env" <<EOF2
NODE_PORT=2222
SECRET_KEY=$secret
EOF2
  chmod 600 "$root/.env"
  cat > "$root/docker-compose.yml" <<'YAML'
services:
  remnanode:
    image: remnawave/node:latest
    container_name: remnanode
    hostname: remnanode
    restart: always
    network_mode: host
    cap_add: [NET_ADMIN]
    env_file: .env
    ulimits:
      nofile: {soft: 1048576, hard: 1048576}
YAML
  docker compose -f "$root/docker-compose.yml" config >/dev/null
  docker compose -f "$root/docker-compose.yml" pull -q
  docker compose -f "$root/docker-compose.yml" up -d
}

write_http_server(){
  cat > /etc/nginx/conf.d/remnawave-http.conf <<EOF2
server {
  listen 80;
  server_name $*;
  root /var/www/html;
  location /.well-known/acme-challenge/ { try_files \$uri =404; }
  location / { return 301 https://\$host\$request_uri; }
}
EOF2
  nginx -t >/dev/null && systemctl reload nginx
}

issue_cert(){
  local domain="$1" email="$2"
  mkdir -p /var/www/html/.well-known/acme-challenge
  if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" && -f "/etc/letsencrypt/live/$domain/privkey.pem" ]]; then return 0; fi
  certbot certonly --webroot -w /var/www/html --non-interactive --agree-tos --email "$email" --key-type ecdsa -d "$domain"
}

tls_params(){
  cat > /etc/nginx/conf.d/ssl-params.conf <<'EOF2'
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;
resolver 1.1.1.1 8.8.8.8 valid=300s;
resolver_timeout 5s;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options SAMEORIGIN always;
add_header Referrer-Policy strict-origin-when-cross-origin always;
EOF2
}

write_panel_vhosts(){
  cat > /etc/nginx/conf.d/remnawave-web.conf <<EOF2
server {
  listen 127.0.0.1:9443 ssl http2;
  server_name ${DOMAIN_PANEL};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_PANEL}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_PANEL}/privkey.pem;
  include /etc/nginx/conf.d/ssl-params.conf;
  location /api/auth/login { limit_req zone=login_limit burst=3 nodelay; proxy_pass http://127.0.0.1:3000; include /etc/nginx/proxy_params; proxy_set_header X-Forwarded-Proto https; }
  location /api/ { limit_req zone=api_limit burst=30 nodelay; proxy_pass http://127.0.0.1:3000; include /etc/nginx/proxy_params; proxy_set_header X-Forwarded-Proto https; }
  location / { proxy_pass http://127.0.0.1:3000; include /etc/nginx/proxy_params; proxy_set_header X-Forwarded-Proto https; }
}
server {
  listen 127.0.0.1:9443 ssl http2;
  server_name ${DOMAIN_SUB};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_SUB}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_SUB}/privkey.pem;
  include /etc/nginx/conf.d/ssl-params.conf;
  location / { proxy_pass http://127.0.0.1:3010; include /etc/nginx/proxy_params; proxy_set_header X-Forwarded-Proto https; }
}
EOF2
}

write_sni_router(){
  mkdir -p /var/www/reality-site
  cat > /var/www/reality-site/index.html <<'EOF2'
<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Сервис</title><h1>Добро пожаловать</h1><p>Веб-сервис работает в штатном режиме.</p>
EOF2
  cat > /etc/nginx/conf.d/reality-site.conf <<EOF2
server {
  listen 127.0.0.1:9450 ssl;
  server_name ${DOMAIN_REALITY};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_REALITY}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_REALITY}/privkey.pem;
  include /etc/nginx/conf.d/ssl-params.conf;
  root /var/www/reality-site;
  location / { try_files \$uri \$uri/ /index.html; }
}
EOF2
  cat > "$STREAM_CONF" <<EOF2
stream {
  map \$ssl_preread_server_name \$remna_backend {
    default 127.0.0.1:9444;
    ${DOMAIN_REALITY} 127.0.0.1:8444;
    ${DOMAIN_PANEL} 127.0.0.1:9443;
    ${DOMAIN_SUB} 127.0.0.1:9443;
  }
  server {
    listen 443;
    proxy_connect_timeout 5s;
    proxy_timeout 1h;
    proxy_pass \$remna_backend;
    ssl_preread on;
  }
}
EOF2
  cat > /etc/nginx/conf.d/reality-reject.conf <<'EOF2'
server { listen 127.0.0.1:9444 ssl; ssl_reject_handshake on; }
EOF2
  grep -Fq "include $STREAM_CONF;" /etc/nginx/nginx.conf || sed -i "/^http {/i include $STREAM_CONF;" /etc/nginx/nginx.conf
  nginx -t >/dev/null && systemctl reload nginx
}

install_subscription(){
  mkdir -p "$BASE/subscription"
  cat > "$BASE/subscription/.env" <<EOF2
APP_PORT=3010
REMNAWAVE_PANEL_URL=http://remnawave:3000
REMNAWAVE_API_TOKEN=$SUB_API_TOKEN
CUSTOM_SUB_PREFIX=sub
TRUST_PROXY=1
EOF2
  chmod 600 "$BASE/subscription/.env"
  cat > "$BASE/subscription/docker-compose.yml" <<'YAML'
services:
  subscription-page:
    image: remnawave/subscription-page:latest
    container_name: remnawave-subscription-page
    restart: always
    env_file: .env
    ports: ["127.0.0.1:3010:3010"]
    networks: [remnawave-network]
networks:
  remnawave-network:
    external: true
    name: remnawave-network
YAML
  docker network inspect remnawave-network >/dev/null 2>&1 || docker network create remnawave-network >/dev/null
  docker compose -f "$BASE/subscription/docker-compose.yml" config >/dev/null
  docker compose -f "$BASE/subscription/docker-compose.yml" pull -q
  docker compose -f "$BASE/subscription/docker-compose.yml" up -d
}

install_hysteria2(){
  HYSTERIA2_PASSWORD="${HYSTERIA2_PASSWORD:-$(rand 32)}"
  mkdir -p "$BASE/hysteria2"
  cat > "$BASE/hysteria2/config.json" <<EOF2
{
  "inbounds":[{"type":"hysteria2","listen":"0.0.0.0","listen_port":8443,"users":[{"name":"default","password":"${HYSTERIA2_PASSWORD}"}],"masquerade":"https://${DOMAIN_REALITY}/","tls":{"enabled":true,"server_name":"${DOMAIN_REALITY}","certificate_path":"/etc/letsencrypt/live/${DOMAIN_REALITY}/fullchain.pem","key_path":"/etc/letsencrypt/live/${DOMAIN_REALITY}/privkey.pem"}}],
  "outbounds":[{"type":"direct"}]
}
EOF2
  cat > "$BASE/hysteria2/docker-compose.yml" <<'YAML'
services:
  hysteria2:
    image: ghcr.io/sagernet/sing-box:latest
    container_name: remnawave-hysteria2
    restart: always
    network_mode: host
    volumes:
      - ./config.json:/etc/sing-box/config.json:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    command: ["-c","/etc/sing-box/config.json"]
YAML
  docker compose -f "$BASE/hysteria2/docker-compose.yml" config >/dev/null
  docker compose -f "$BASE/hysteria2/docker-compose.yml" pull -q
  docker compose -f "$BASE/hysteria2/docker-compose.yml" up -d
}

install_monitoring(){
  local root="$BASE/monitoring"; mkdir -p "$root"
  cat > "$root/prometheus.yml" <<EOF2
global:
  scrape_interval: 30s
scrape_configs:
  - job_name: node
    static_configs: [{targets: ['node-exporter:9100']}]
  - job_name: cadvisor
    static_configs: [{targets: ['cadvisor:8080']}]
  - job_name: remnawave
    metrics_path: /metrics
    basic_auth:
      username: admin
      password: ${METRICS_PASS}
    static_configs: [{targets: ['host.docker.internal:3001']}]
EOF2
  cat > "$root/docker-compose.yml" <<'YAML'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: remnawave-prometheus
    restart: always
    extra_hosts: ["host.docker.internal:host-gateway"]
    volumes: ["./prometheus.yml:/etc/prometheus/prometheus.yml:ro", "prom_data:/prometheus"]
    ports: ["127.0.0.1:9090:9090"]
  node-exporter:
    image: prom/node-exporter:latest
    container_name: remnawave-node-exporter
    restart: always
    network_mode: host
    pid: host
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: remnawave-cadvisor
    restart: always
    privileged: true
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
    ports: ["127.0.0.1:8080:8080"]
volumes:
  prom_data:
YAML
  docker compose -f "$root/docker-compose.yml" config >/dev/null
  docker compose -f "$root/docker-compose.yml" pull -q
  docker compose -f "$root/docker-compose.yml" up -d
}

install_timers(){
  cat > /usr/local/sbin/remnawave-healthcheck.sh <<'EOF2'
#!/usr/bin/env bash
set -u
compose_files=(/opt/remnawave/docker-compose.yml /opt/remnawave/subscription/docker-compose.yml /opt/remnawave/node/docker-compose.yml /opt/remnawave/hysteria2/docker-compose.yml /opt/remnawave-edge/node/docker-compose.yml)
for f in "${compose_files[@]}"; do
  [[ -f "$f" ]] || continue
  expected=$(docker compose -f "$f" config --services 2>/dev/null || true)
  running=$(docker compose -f "$f" ps --status running --services 2>/dev/null || true)
  missing=0
  while IFS= read -r svc; do
    [[ -z "$svc" ]] && continue
    if ! grep -Fxq "$svc" <<<"$running"; then missing=1; break; fi
  done <<<"$expected"
  if [[ $missing -eq 1 ]]; then
    docker compose -f "$f" up -d >/dev/null 2>&1 || true
  fi
done
if [[ -f /opt/remnawave/docker-compose.yml ]] && ! curl -fsS --max-time 5 http://127.0.0.1:3000/api/auth/status >/dev/null 2>&1; then
  docker compose -f /opt/remnawave/docker-compose.yml restart >/dev/null 2>&1 || true
fi
systemctl is-active --quiet nginx || systemctl restart nginx || true
EOF2
  chmod 700 /usr/local/sbin/remnawave-healthcheck.sh
  cat > /usr/local/sbin/remnawave-backup.sh <<'EOF2'
#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p /var/backups/remnawave
stamp=$(date +%Y%m%d-%H%M%S)
out="/var/backups/remnawave/remnawave-$stamp.tgz"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if docker ps --format '{{.Names}}' | grep -qx remnawave-db; then
  pgpass=$(awk -F= '$1=="POSTGRES_PASSWORD"{print substr($0,index($0,"=")+1)}' /opt/remnawave/.env)
  db="$tmp/remnawave-db-$stamp.sql"
  docker exec -e PGPASSWORD="$pgpass" remnawave-db pg_dump -U postgres postgres > "$db"
fi
args=(/opt/remnawave /opt/remnawave-edge /etc/nginx/conf.d /etc/nginx/stream.conf /etc/letsencrypt)
if [[ -f "$tmp/remnawave-db-$stamp.sql" ]]; then
  args+=( -C "$tmp" "remnawave-db-$stamp.sql" )
fi
tar --ignore-failed-read -czf "$out" "${args[@]}" 2>/dev/null
chmod 600 "$out"
find /var/backups/remnawave -type f -mtime +14 -delete
EOF2
  chmod 700 /usr/local/sbin/remnawave-backup.sh
  cat > /usr/local/sbin/remnawave-nginx-reload.sh <<'EOF2'
#!/usr/bin/env bash
set -Eeuo pipefail
nginx -t && systemctl reload nginx
EOF2
  chmod 700 /usr/local/sbin/remnawave-nginx-reload.sh
  cat > /etc/systemd/system/remnawave-healthcheck.service <<'EOF2'
[Unit]
Description=Проверка состояния Remnawave
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/remnawave-healthcheck.sh
EOF2
  cat > /etc/systemd/system/remnawave-healthcheck.timer <<'EOF2'
[Unit]
Description=Проверка состояния Remnawave timer
[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Persistent=true
[Install]
WantedBy=timers.target
EOF2
  cat > /etc/systemd/system/remnawave-backup.service <<'EOF2'
[Unit]
Description=Резервная копия Remnawave
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/remnawave-backup.sh
EOF2
  cat > /etc/systemd/system/remnawave-backup.timer <<'EOF2'
[Unit]
Description=Резервная копия Remnawave timer
[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
[Install]
WantedBy=timers.target
EOF2
  cat > /etc/systemd/system/remnawave-cert-renew.service <<'EOF2'
[Unit]
Description=Обновление сертификатов Let's Encrypt для Remnawave
[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --deploy-hook /usr/local/sbin/remnawave-nginx-reload.sh
EOF2
  cat > /etc/systemd/system/remnawave-cert-renew.timer <<'EOF2'
[Unit]
Description=Remnawave certificate renewal
[Timer]
OnCalendar=*-*-* 04:15:00
Persistent=true
[Install]
WantedBy=timers.target
EOF2
  systemctl daemon-reload
  systemctl enable --now remnawave-healthcheck.timer remnawave-backup.timer remnawave-cert-renew.timer >/dev/null
}

configure_remote_backup(){
  [[ -n "${BACKUP_REMOTE:-}" ]] || return 0
  command -v rclone >/dev/null || die 'rclone не установлен.'
  command -v age >/dev/null || die 'age не установлен.'
  rclone listremotes | grep -q "^${BACKUP_REMOTE%%:*}:" || die "rclone remote ${BACKUP_REMOTE%%:*} не найден."
  local key="$BASE/backup-age.key"
  [[ -f "$key" ]] || age-keygen -o "$key"
  chmod 600 "$key"
  local pub; pub="$(awk '/public key:/{print $4}' "$key")"
  cat > /usr/local/sbin/remnawave-remote-backup.sh <<EOF2
#!/usr/bin/env bash
set -Eeuo pipefail
stamp=\$(date +%Y%m%d-%H%M%S)
tmp=\$(mktemp -d); trap 'rm -rf "\$tmp"' EXIT
/usr/local/sbin/remnawave-backup.sh
latest=\$(ls -1t /var/backups/remnawave/remnawave-*.tgz | head -1)
age -r '$pub' -o "\$tmp/remnawave-\$stamp.tgz.age" "\$latest"
rclone copy "\$tmp/remnawave-\$stamp.tgz.age" '$BACKUP_REMOTE' --quiet
EOF2
  chmod 700 /usr/local/sbin/remnawave-remote-backup.sh
  cat > /etc/systemd/system/remnawave-remote-backup.service <<'EOF2'
[Unit]
Description=Зашифрованная удалённая копия Remnawave
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/remnawave-remote-backup.sh
EOF2
  cat > /etc/systemd/system/remnawave-remote-backup.timer <<'EOF2'
[Unit]
Description=Зашифрованная удалённая копия Remnawave timer
[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
[Install]
WantedBy=timers.target
EOF2
  systemctl daemon-reload
  systemctl enable --now remnawave-remote-backup.timer >/dev/null
  ok 'Шифрованный remote backup настроен.'
}

write_bootstrap(){
  cat > "$BOOTSTRAP_FILE" <<EOF2
PANEL_IP=$(public_ip)
PANEL_API_URL=https://${DOMAIN_PANEL}
PANEL_API_TOKEN=${API_TOKEN}
NODE_SECRET_KEY=${NODE_SECRET_KEY}
PROFILE_UUID=${PROFILE_UUID}
INBOUND_UUID=${INBOUND_UUID}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY}
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY}
REALITY_SHORT_ID=${REALITY_SHORT_ID}
EOF2
  chmod 600 "$BOOTSTRAP_FILE"
}

write_credentials(){
  cat > "$CREDS_FILE" <<EOF2
Remnawave Manager $VERSION
Panel: https://${DOMAIN_PANEL}
Subscription: https://${DOMAIN_SUB}
Reality SNI: ${DOMAIN_REALITY}
Admin username: ${ADMIN_USERNAME}
Admin password: ${ADMIN_PASSWORD}
API token: ${API_TOKEN}
Subscription API token: ${SUB_API_TOKEN}
Node secret: ${NODE_SECRET_KEY}
Profile UUID: ${PROFILE_UUID:-n/a}
Inbound UUID: ${INBOUND_UUID:-n/a}
Host UUID: ${HOST_UUID:-n/a}
Reality public key: ${REALITY_PUBLIC_KEY}
Reality short ID: ${REALITY_SHORT_ID}
Hysteria2 password: ${HYSTERIA2_PASSWORD:-disabled}
EOF2
  chmod 600 "$CREDS_FILE"
}

finish_config(){
  cat >> "$ENV_FILE" <<EOF2
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
SUB_API_TOKEN=${SUB_API_TOKEN}
NODE_SECRET_KEY=${NODE_SECRET_KEY}
PROFILE_UUID=${PROFILE_UUID}
INBOUND_UUID=${INBOUND_UUID}
HOST_UUID=${HOST_UUID:-}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY}
REALITY_SHORT_ID=${REALITY_SHORT_ID}
EOF2
  chmod 600 "$ENV_FILE"
}

setup_panel_web(){
  write_http_server "$DOMAIN_PANEL" "$DOMAIN_SUB" "$DOMAIN_REALITY"
  issue_cert "$DOMAIN_PANEL" "$ADMIN_EMAIL"
  issue_cert "$DOMAIN_SUB" "$ADMIN_EMAIL"
  issue_cert "$DOMAIN_REALITY" "$ADMIN_EMAIL"
  mkdir -p /etc/nginx/conf.d
  cat > /etc/nginx/conf.d/rate-limit.conf <<'EOF2'
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=30r/s;
EOF2
  tls_params
  write_panel_vhosts
  write_sni_router
}

# -----------------------------------------------------------------------------
# v24 additions: hardening, selfsteal, Telegram alerts, Xray Checker, core manager
# and safe upstream addon bridge.
# -----------------------------------------------------------------------------

configure_kernel(){
  [[ $DRY_RUN -eq 1 ]] && { log "[DRY-RUN] BBR=$BBR DISABLE_IPV6=$DISABLE_IPV6"; return 0; }
  if [[ $BBR -eq 1 ]]; then
    cat > /etc/sysctl.d/99-remnawave.conf <<EOF_SYS
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF_SYS
  elif [[ -f /etc/sysctl.d/99-remnawave.conf ]]; then
    sed -i '/^net\.core\.default_qdisc=/d;/^net\.ipv4\.tcp_congestion_control=/d' /etc/sysctl.d/99-remnawave.conf
  fi
  touch /etc/sysctl.d/99-remnawave.conf
  sed -i '/^net\.ipv6\.conf\.all\.disable_ipv6=/d;/^net\.ipv6\.conf\.default\.disable_ipv6=/d' /etc/sysctl.d/99-remnawave.conf
  if [[ $DISABLE_IPV6 -eq 1 ]]; then
    cat >> /etc/sysctl.d/99-remnawave.conf <<EOF_SYS
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF_SYS
  fi
  modprobe tcp_bbr 2>/dev/null || true
  sysctl --system >/dev/null 2>&1 || warn 'sysctl --system завершился с предупреждением.'
  ok 'Настройки ядра Linux применены.'
}

configure_node_logs(){
  local root="$1" compose
  [[ $DRY_RUN -eq 1 ]] && return 0
  compose="$root/docker-compose.yml"
  [[ -f "$compose" ]] || return 0
  mkdir -p /var/log/remnanode; chmod 750 /var/log/remnanode
  cp -a "$compose" "$compose.bak.$(date +%Y%m%d-%H%M%S)"
  if ! grep -q '/var/log/remnanode:/var/log/remnanode' "$compose"; then
    python3 - "$compose" <<'PY_NODELOG'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
needle='    env_file: .env\n'
if needle in s and '/var/log/remnanode:/var/log/remnanode' not in s:
    s=s.replace(needle, needle+'    volumes:\n      - /var/log/remnanode:/var/log/remnanode\n',1)
p.write_text(s)
PY_NODELOG
  fi
  docker compose -f "$compose" config >/dev/null || die 'Node compose не прошёл docker compose config после добавления log mount.'
  cat > /etc/logrotate.d/remnanode <<'EOF_ROTATE'
/var/log/remnanode/*.log {
  size 50M
  rotate 5
  compress
  missingok
  notifempty
  copytruncate
}
EOF_ROTATE
  docker compose -f "$compose" up -d remnanode
}

set_gzip(){
  [[ $DRY_RUN -eq 1 ]] && return 0
  cat > /etc/nginx/conf.d/remnawave-gzip.conf <<'EOF_GZIP'
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_min_length 1024;
gzip_types application/javascript application/json application/manifest+json application/xml application/wasm font/opentype font/eot font/otf font/ttf image/svg+xml text/css text/javascript text/plain text/xml;
server_names_hash_bucket_size 64;
EOF_GZIP
}

configure_admin_ip(){
  [[ -n "${ADMIN_IP:-}" ]] || return 0
  validate_ip "$ADMIN_IP" || die '--admin-ip должен быть IPv4.'
  [[ $DRY_RUN -eq 1 ]] && { log "[DRY-RUN] SSH будет разрешён только с $ADMIN_IP"; return 0; }
  local p; p="$(ssh_port)"
  ufw delete allow "$p/tcp" >/dev/null 2>&1 || true
  ufw allow from "$ADMIN_IP" to any port "$p" proto tcp >/dev/null
  ok "SSH ограничен IP $ADMIN_IP."
}

telegram_send(){
  [[ $TELEGRAM_ALERTS -eq 1 ]] || return 0
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]] || return 0
  local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
  local args=(--data-urlencode "chat_id=$TELEGRAM_CHAT_ID" --data-urlencode "text=$1")
  [[ -n "${TELEGRAM_THREAD_ID:-}" ]] && args+=(--data-urlencode "message_thread_id=$TELEGRAM_THREAD_ID")
  curl -fsS --max-time 15 -X POST "$url" "${args[@]}" >/dev/null 2>&1 || true
}

install_telegram_alerts(){
  [[ $TELEGRAM_ALERTS -eq 1 ]] || return 0
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]] || die '--telegram-alerts требует TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID.'
  cat >> "$ENV_FILE" <<EOF_TG
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
TELEGRAM_THREAD_ID=${TELEGRAM_THREAD_ID:-}
EOF_TG
  chmod 600 "$ENV_FILE"
  telegram_send "Remnawave Manager $VERSION: Telegram alerts enabled on $(hostname)"
}

install_selfsteal(){
  local site='/var/www/reality-site'
  mkdir -p "$site"
  case "${SELFSTEAL_TEMPLATE:-simple}" in
    simple)
      cat > "$site/index.html" <<'EOF_SITE'
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Сервис</title><style>body{font:16px system-ui,sans-serif;margin:0;background:#f5f7fa;color:#17202a}main{max-width:760px;margin:12vh auto;padding:32px}h1{font-size:40px}p{line-height:1.6;color:#4d5966}</style></head><body><main><h1>Добро пожаловать</h1><p>Веб-сервис работает в штатном режиме.</p></main></body></html>
EOF_SITE
      ;;
    business)
      cat > "$site/index.html" <<'EOF_SITE'
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Technology & Services</title><style>body{font-family:Arial,sans-serif;margin:0;color:#222}header{padding:48px 8%;background:#eef2f6}section{padding:40px 8%;max-width:900px}nav a{margin-right:20px;color:#333;text-decoration:none}</style></head><body><header><nav><a href="/">Home</a><a href="/about">About</a><a href="/contact">Contact</a></nav><h1>Technology & Services</h1><p>Reliable solutions for modern businesses.</p></header><section><h2>Our services</h2><p>Infrastructure, software and consulting for teams that need dependable systems.</p></section></body></html>
EOF_SITE
      ;;
    nothing)
      cat > "$site/index.html" <<'EOF_SITE'
<!doctype html><html><head><meta charset="utf-8"><title></title></head><body></body></html>
EOF_SITE
      ;;
    *) die 'Шаблон маскировки: simple|business|nothing' ;;
  esac
  ok "SelfSteal template: ${SELFSTEAL_TEMPLATE:-simple}."
}

install_xray_checker(){
  local root="/opt/xray-checker" suburl="${SUBSCRIPTION_URL:-}" interval="${CHECK_INTERVAL:-300}"
  [[ -n "$suburl" ]] || die 'checker-install требует SUBSCRIPTION_URL=https://.../<shortUuid>.'
  [[ "$interval" =~ ^[0-9]+$ && "$interval" -ge 30 && "$interval" -le 86400 ]] || die 'CHECK_INTERVAL: 30..86400.'
  mkdir -p "$root"
  cat > "$root/docker-compose.yml" <<EOF_XCHK
services:
  xray-checker:
    image: kutovoys/xray-checker:latest
    container_name: xray-checker
    restart: always
    environment:
      SUBSCRIPTION_URL: "$suburl"
      CHECK_INTERVAL: "$interval"
    ports: ["127.0.0.1:2112:2112"]
  xray-checker-statuspage:
    image: ghcr.io/mrvibecodic/xray-checker-statuspage:go-build
    container_name: xray-checker-statuspage
    restart: always
    environment:
      CHECKER_URL: "http://xray-checker:2112"
    ports: ["127.0.0.1:8080:8080", "127.0.0.1:8081:8081"]
EOF_XCHK
  docker compose -f "$root/docker-compose.yml" config >/dev/null
  docker compose -f "$root/docker-compose.yml" pull -q
  docker compose -f "$root/docker-compose.yml" up -d
  cat > "$root/README.txt" <<EOF_INFO
Xray Checker
Subscription: $suburl
Metrics/API: http://127.0.0.1:2112
Status page: http://127.0.0.1:8080
This component is intentionally designed for a separate monitoring VDS.
EOF_INFO
  chmod 600 "$root/README.txt"
  ok 'Xray Checker установлен на отдельном VDS.'
}

xray_arch(){ case "$(dpkg --print-architecture)" in amd64) echo 64;; arm64) echo arm64-v8a;; *) die 'Xray core manager поддерживает amd64/arm64.';; esac; }
install_xray_core(){
  local root="${1:-$BASE/node}" src="${2:-official}" repo api asset zip dgst version tmp bin backup expected actual
  [[ -f "$root/docker-compose.yml" ]] || die "Node compose не найден: $root/docker-compose.yml"
  [[ "$src" == official || "$src" == joly ]] || die 'Источник Xray: official|joly.'
  repo='XTLS/Xray-core'; [[ "$src" == joly ]] && repo='Jolymmiles/Xray-core'
  api="$(curl -fsSL --max-time 20 "https://api.github.com/repos/$repo/releases?per_page=5")" || die 'GitHub API недоступен для управления ядром Xray.'
  version="$(jq -r 'map(select(.draft==false and .prerelease==false))[0].tag_name // empty' <<<"$api")"
  [[ -n "$version" ]] || die 'Релиз Xray не найден.'
  asset="Xray-linux-$(xray_arch).zip"
  zip="$(jq -r --arg a "$asset" 'map(select(.draft==false and .prerelease==false))[0].assets[]? | select(.name==$a) | .browser_download_url' <<<"$api" | head -1)"
  dgst="$(jq -r --arg a "$asset.dgst" 'map(select(.draft==false and .prerelease==false))[0].assets[]? | select(.name==$a) | .browser_download_url' <<<"$api" | head -1)"
  [[ -n "$zip" ]] || die "Asset $asset не найден в $repo $version."
  tmp="$(mktemp -d)"
  curl -fsSL --max-time 120 -o "$tmp/xray.zip" "$zip"
  [[ -n "$dgst" ]] && curl -fsSL --max-time 30 -o "$tmp/xray.dgst" "$dgst" || true
  (cd "$tmp" && unzip -q xray.zip)
  bin="$tmp/xray"; [[ -x "$bin" ]] || die 'В архиве Xray не найден исполняемый файл.'
  if [[ -s "$tmp/xray.dgst" ]]; then
    expected="$(awk '$1=="SHA256" {print $2}' "$tmp/xray.dgst" | head -1)"
    actual="$(sha256sum "$bin" | awk '{print $1}')"
    [[ -n "$expected" && "$expected" == "$actual" ]] || die 'SHA256 Xray не совпал.'
  fi
  backup="$root/docker-compose.yml.xraybak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$root/docker-compose.yml" "$backup"
  cp -f "$bin" "$root/xray-custom"; chmod 755 "$root/xray-custom"
  if ! grep -q './xray-custom:/usr/local/bin/xray' "$root/docker-compose.yml"; then
    python3 - "$root/docker-compose.yml" <<'PY_XCORE'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
needle='    env_file: .env\n'
if needle not in s: raise SystemExit('compose anchor not found')
s=s.replace(needle, needle+'    volumes:\n      - ./xray-custom:/usr/local/bin/xray\n',1)
p.write_text(s)
PY_XCORE
  fi
  if ! docker compose -f "$root/docker-compose.yml" config >/dev/null; then
    cp -a "$backup" "$root/docker-compose.yml"; rm -f "$root/xray-custom"; die 'Проверка Compose не пройдена; выполнен откат.'
  fi
  docker compose -f "$root/docker-compose.yml" up -d remnanode
  cat > "$root/xray-core.state" <<EOF_STATE
source=$src
repo=$repo
version=$version
asset=$asset
installed_at=$(date -Is)
EOF_STATE
  chmod 600 "$root/xray-core.state"
  rm -rf "$tmp"
  ok "Custom Xray core установлен: $repo $version"
}
restore_xray_core(){
  local root="${1:-$BASE/node}"
  [[ -f "$root/docker-compose.yml" ]] || die 'Node compose не найден.'
  sed -i '/- \.\/xray-custom:\/usr\/local\/bin\/xray/d' "$root/docker-compose.yml"
  rm -f "$root/xray-custom" "$root/xray-core.state"
  docker compose -f "$root/docker-compose.yml" config >/dev/null
  docker compose -f "$root/docker-compose.yml" up -d remnanode
  ok 'Штатное ядро Xray восстановлено.'
}

download_upstream(){
  local url="$1" out="$2"; local path repo file
  if curl -fsSL --max-time 90 -o "$out" "$url"; then return 0; fi
  # Резервный CDN jsDelivr, если GitHub недоступен.
  if [[ "$url" =~ https://github.com/([^/]+/[^/]+)/raw/main/(.*)$ ]]; then
    repo="${BASH_REMATCH[1]}"; path="${BASH_REMATCH[2]}"
    curl -fsSL --max-time 90 -o "$out" "https://cdn.jsdelivr.net/gh/${repo}@main/${path}"
    return $?
  fi
  return 1
}

install_upstream_addon(){
  local addon="$1" url script
  case "$addon" in
    remnawave) url='https://github.com/DigneZzZ/remnawave-scripts/raw/main/remnawave.sh'; script='remnawave.sh' ;;
    remnanode) url='https://github.com/DigneZzZ/remnawave-scripts/raw/main/remnanode.sh'; script='remnanode.sh' ;;
    egames) url='https://github.com/eGamesAPI/remnawave-reverse-proxy/raw/main/install_remnawave.sh'; script='remnawave_reverse.sh' ;;
    selfsteal) url='https://github.com/DigneZzZ/remnawave-scripts/raw/main/selfsteal.sh'; script='selfsteal.sh' ;;
    wtm) url='https://github.com/DigneZzZ/remnawave-scripts/raw/main/wtm.sh'; script='wtm.sh' ;;
    netbird) url='https://github.com/DigneZzZ/remnawave-scripts/raw/main/netbird.sh'; script='netbird.sh' ;;
    *) die 'Модуль: remnawave|remnanode|selfsteal|wtm|netbird|egames' ;;
  esac
  mkdir -p /opt/remnawave-addons
  download_upstream "$url" "/opt/remnawave-addons/$script" || die "Не удалось загрузить модуль $addon ни с GitHub, ни через jsDelivr."
  chmod 700 "/opt/remnawave-addons/$script"
  ok "Подключаю upstream addon $addon."
  if [[ "$addon" == remnawave || "$addon" == remnanode ]]; then
    "/opt/remnawave-addons/$script" @ install-script
  else
    "/opt/remnawave-addons/$script"
  fi
}

install_single(){
  install_base; configure_security; configure_kernel
  check_dns "$DOMAIN_PANEL"; check_dns "$DOMAIN_SUB"; check_dns "$DOMAIN_REALITY"
  MODE=single write_panel_env
  install_panel_compose; wait_api
  bootstrap_auth; create_subscription_token; get_node_secret; generate_x25519
  create_config_profile
  install_subscription
  write_node_compose "$BASE/node" "$NODE_SECRET_KEY"
  configure_node_logs "$BASE/node"
  create_node '127.0.0.1' AUTO-SINGLE
  create_host "$DOMAIN_REALITY"
  setup_panel_web
  install_selfsteal
  install_telegram_alerts
  [[ $HYSTERIA2 -eq 1 ]] && install_hysteria2
  [[ "${XCORE_SOURCE:-builtin}" != builtin ]] && install_xray_core "$BASE/node" "$XCORE_SOURCE"
  [[ $MONITORING -eq 1 ]] && install_monitoring
  write_firewall single
  configure_admin_ip
  configure_remote_backup
  write_bootstrap; finish_config; write_credentials; install_timers
  ok 'Single VDS установлен.'
  show_result
}

install_panel(){
  install_base; configure_security; configure_kernel
  check_dns "$DOMAIN_PANEL"; check_dns "$DOMAIN_SUB"
  MODE=panel write_panel_env
  install_panel_compose; wait_api
  bootstrap_auth; create_subscription_token; generate_x25519; create_config_profile; install_subscription
  if [[ -n "${EDGE_ADDRESS:-}" ]]; then
    get_node_secret
    create_node "$EDGE_ADDRESS" AUTO-EDGE
    create_host "$DOMAIN_REALITY"
  fi
  write_http_server "$DOMAIN_PANEL" "$DOMAIN_SUB"
  issue_cert "$DOMAIN_PANEL" "$ADMIN_EMAIL"; issue_cert "$DOMAIN_SUB" "$ADMIN_EMAIL"
  cat > /etc/nginx/conf.d/rate-limit.conf <<'EOF2'
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api_limit:30m rate=30r/s;
EOF2
  tls_params; set_gzip; write_panel_vhosts
  nginx -t >/dev/null && systemctl reload nginx
  write_firewall panel; configure_admin_ip; configure_remote_backup; write_bootstrap; finish_config; write_credentials; install_timers
  [[ $MONITORING -eq 1 ]] && install_monitoring
  install_telegram_alerts
  ok 'Panel VDS установлен.'; show_result
}

install_edge(){
  install_base; configure_security; configure_kernel
  check_dns "$DOMAIN_REALITY"
  mkdir -p "$EDGE_BASE"
  cat > "$EDGE_ENV" <<EOF2
MODE=edge
PANEL_IP=$PANEL_IP
DOMAIN_NODE=$DOMAIN_NODE
DOMAIN_REALITY=$DOMAIN_REALITY
NODE_SECRET_KEY=$NODE_SECRET_KEY
EOF2
  chmod 600 "$EDGE_ENV"
  write_node_compose "$EDGE_BASE/node" "$NODE_SECRET_KEY"
  configure_node_logs "$EDGE_BASE/node"
  install_selfsteal
  mkdir -p /var/www/reality-site
  write_http_server "$DOMAIN_REALITY"
  issue_cert "$DOMAIN_REALITY" "$ADMIN_EMAIL"
  tls_params; set_gzip
  cat > /etc/nginx/conf.d/reality-site.conf <<EOF2
server {
  listen 127.0.0.1:9450 ssl;
  server_name ${DOMAIN_REALITY};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_REALITY}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_REALITY}/privkey.pem;
  include /etc/nginx/conf.d/ssl-params.conf;
  root /var/www/reality-site;
  location / { try_files \$uri \$uri/ /index.html; }
}
EOF2
  cat > "$STREAM_CONF" <<EOF2
stream {
  map \$ssl_preread_server_name \$remna_edge_backend {
    default 127.0.0.1:9444;
    ${DOMAIN_REALITY} 127.0.0.1:8444;
  }
  server { listen 443; proxy_pass \$remna_edge_backend; ssl_preread on; proxy_timeout 1h; }
}
EOF2
  cat > /etc/nginx/conf.d/reality-reject.conf <<'EOF2'
server { listen 127.0.0.1:9444 ssl; ssl_reject_handshake on; }
EOF2
  grep -Fq "include $STREAM_CONF;" /etc/nginx/nginx.conf || sed -i "/^http {/i include $STREAM_CONF;" /etc/nginx/nginx.conf
  nginx -t >/dev/null && systemctl reload nginx
  write_firewall edge; configure_admin_ip; install_timers
  ok 'Edge VDS установлен.'
}

check_dns(){
  local d="$1" ip answers
  answers="$(getent ahostsv4 "$d" | awk '{print $1}' | sort -u || true)"
  [[ -n "$answers" ]] || die "DNS A-запись для $d отсутствует."
  ip="$(public_ip)"
  if [[ -n "$ip" && ! " $answers " =~ [[:space:]]$ip[[:space:]] ]]; then warn "DNS $d не совпадает с публичным IP $ip. Если это намеренно, установка продолжится."; else ok "DNS $d: $answers"; fi
}

show_result(){
  cat <<EOF2

${C_GREEN}${C_BOLD}УСТАНОВКА ЗАВЕРШЕНА${C_RESET}
Panel:        https://${DOMAIN_PANEL}
Subscription: https://${DOMAIN_SUB}
Reality SNI:  ${DOMAIN_REALITY}
Admin:        ${ADMIN_USERNAME}
Password:     ${ADMIN_PASSWORD}
API token:    ${API_TOKEN}
Sub token:    ${SUB_API_TOKEN:-n/a}
Profile:      ${PROFILE_UUID}
Inbound:      ${INBOUND_UUID}
Host:         ${HOST_UUID:-n/a}

Секреты:
  $CREDS_FILE
  $ENV_FILE
  $BOOTSTRAP_FILE

SECRET_KEY Node должен совпадать с секретом из карточки Node в Panel.
Удалите credentials.txt после сохранения секретов.
EOF2
}

status(){
  echo "=== Состояние Remnawave $VERSION ==="
  docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'remnawave|remnanode|hysteria|prometheus|cadvisor|node-exporter' || true
  systemctl is-active nginx fail2ban unattended-upgrades 2>/dev/null || true
  systemctl list-timers --all | grep remnawave || true
}

doctor(){
  echo "Remnawave Manager $VERSION"
  echo '[Docker]'
  echo '[Система]'; . /etc/os-release; echo "${PRETTY_NAME:-unknown}"; docker version --format '{{.Server.Version}}' 2>/dev/null || echo FAIL
  echo '[Nginx / веб-сервер]'; nginx -t 2>&1 | tail -5 || true
  echo '[API панели]'; curl -fsS --max-time 5 "$API_LOCAL/auth/status" | jq . 2>/dev/null || echo unavailable
  echo '[Порты]'; ss -lntup | grep -E ':(80|443|2222|3000|3001|3010|8443|8444|9443|9444|9450)\b' || true
  echo '[Контейнеры]'; docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'remnawave|remnanode|hysteria|prometheus|cadvisor|node-exporter' || true
  echo '[Таймеры]'; systemctl list-timers --all | grep remnawave || true
  echo '[Firewall UFW]'; ufw status || true
}

backup(){ /usr/local/sbin/remnawave-backup.sh; ok "Backup: $BACKUP_BASE"; }

update_one(){
  local d="$1"; [[ -f "$d/docker-compose.yml" ]] || return 0
  (cd "$d" && docker compose pull -q && docker compose up -d --wait --wait-timeout 180)
}
update(){
  backup
  local snap="$BACKUP_BASE/$(ls -1t "$BACKUP_BASE"/remnawave-*.tgz 2>/dev/null | head -1 | xargs -r basename)"
  # Официальный порядок: Panel -> Node -> Subscription.
  if ! update_one "$BASE" || ! update_one "$BASE/node" || ! update_one "$EDGE_BASE/node" || ! update_one "$BASE/subscription" || ! update_one "$BASE/hysteria2"; then
    warn 'Обновление одного из компонентов не удалось. Возвращаем конфигурацию из последнего backup.'
    [[ -f "$snap" ]] && restore "$snap" || true
    die 'Обновление отменено.'
  fi
  if [[ -f "$BASE/docker-compose.yml" ]] && ! curl -fsS --max-time 8 "$API_LOCAL/auth/status" >/dev/null 2>&1; then
    warn 'Panel API не поднялся после update. Выполняю restore конфигурации.'
    [[ -f "$snap" ]] && restore "$snap" || true
    die 'Проверка панели после обновления не пройдена.'
  fi
  nginx -t && systemctl reload nginx
  ok 'Обновление завершено; перед обновлением создан backup и проверен API.'
}

restore(){
  local archive="$1" tmp db_member pgpass
  [[ -f "$archive" ]] || die "Файл не найден: $archive"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  if file "$archive" | grep -qi age; then
    [[ -f "$BASE/backup-age.key" ]] || die 'Для AGE restore не найден /opt/remnawave/backup-age.key.'
    age -d -i "$BASE/backup-age.key" -o "$tmp/restore.tgz" "$archive"
    archive="$tmp/restore.tgz"
  fi
  tar -tzf "$archive" >/dev/null || die 'Архив повреждён или не является tar.gz.'
  db_member="$(tar -tzf "$archive" | sed 's#^\./##' | grep -E '(^|/)remnawave-db-[0-9-]+\.sql$' | head -1 || true)"

  for d in "$BASE" "$BASE/subscription" "$BASE/node" "$EDGE_BASE/node" "$BASE/hysteria2"; do
    [[ -f "$d/docker-compose.yml" ]] && (cd "$d" && docker compose down || true)
  done

  tar -xzf "$archive" -C / || die 'Не удалось распаковать backup.'

  if [[ -f "$BASE/docker-compose.yml" && -n "$db_member" ]]; then
    cd "$BASE"
    docker compose up -d remnawave-db remnawave-redis
    for _ in {1..60}; do
      if docker exec remnawave-db pg_isready -U postgres -d postgres >/dev/null 2>&1; then break; fi
      sleep 2
    done
    docker exec remnawave-db pg_isready -U postgres -d postgres >/dev/null 2>&1 || die 'PostgreSQL не стал готов после restore.'
    pgpass="$(awk -F= '$1=="POSTGRES_PASSWORD"{print substr($0,index($0,"=")+1)}' "$BASE/.env" | tail -1)"
    [[ -n "$pgpass" ]] || die 'После restore не найден POSTGRES_PASSWORD.'
    docker exec -e PGPASSWORD="$pgpass" remnawave-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;' >/dev/null
    tar -xOf "$archive" "$db_member" | docker exec -i -e PGPASSWORD="$pgpass" remnawave-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 >/dev/null || die 'Импорт PostgreSQL dump не выполнен.'
  elif [[ -f "$BASE/docker-compose.yml" ]]; then
    warn 'В backup не найден PostgreSQL dump; конфигурация будет восстановлена без БД.'
  fi

  for d in "$BASE" "$BASE/subscription" "$BASE/node" "$EDGE_BASE/node" "$BASE/hysteria2" "$BASE/monitoring"; do
    [[ -f "$d/docker-compose.yml" ]] || continue
    (cd "$d" && docker compose up -d) || die "Не удалось поднять Compose: $d"
  done
  nginx -t || die 'Проверка Nginx после restore не пройдена.'
  systemctl reload nginx
  trap - RETURN
  rm -rf "$tmp"
  ok 'Restore завершён, включая импорт PostgreSQL dump при наличии в архиве.'
}

uninstall(){
  [[ $AUTO_YES -eq 1 ]] || { read -r -p 'Введите DELETE для подтверждения: ' x; [[ "$x" == DELETE ]] || die 'Отменено.'; }
  for d in "$BASE" "$BASE/subscription" "$BASE/node" "$EDGE_BASE/node" "$BASE/hysteria2" "$BASE/monitoring"; do [[ -f "$d/docker-compose.yml" ]] && (cd "$d" && docker compose down || true); done
  systemctl disable --now remnawave-healthcheck.timer remnawave-backup.timer remnawave-cert-renew.timer remnawave-remote-backup.timer 2>/dev/null || true
  rm -f /etc/systemd/system/remnawave-*.service /etc/systemd/system/remnawave-*.timer /usr/local/sbin/remnawave-*.sh
  rm -f /etc/nginx/conf.d/remnawave-*.conf /etc/nginx/conf.d/reality-*.conf /etc/nginx/conf.d/ssl-params.conf /etc/nginx/conf.d/rate-limit.conf "$STREAM_CONF"
  sed -i "/include ${STREAM_CONF//\//\\/};/d" /etc/nginx/nginx.conf 2>/dev/null || true
  systemctl daemon-reload
  nginx -t >/dev/null && systemctl reload nginx || true
  ok 'Remnawave сервисы удалены; backups сохранены.'
}

wizard(){
  local mode="$1"
  case "$mode" in
    single|panel)
      ask DOMAIN_PANEL 'Домен Panel' '' validate_domain
      ask DOMAIN_SUB 'Домен Subscription Page' '' validate_domain
      ask DOMAIN_REALITY 'Домен SNI для REALITY' '' validate_domain
      ask ADMIN_EMAIL 'Email для сертификата ACME' '' validate_email
      ADMIN_USERNAME="${ADMIN_USERNAME:-$ADMIN_EMAIL}"
      if [[ -z "${ADMIN_PASSWORD:-}" ]]; then ADMIN_PASSWORD="$(rand 24)Aa1"; fi
      if [[ "$mode" == single ]]; then
        : # SECRET_KEY fetched automatically from /api/keygen
      fi
      if [[ "$mode" == panel ]]; then
        if [[ -z "${EDGE_ADDRESS:-}" && $AUTO_YES -eq 0 ]]; then read -r -p 'IP Edge (Enter — пропустить): ' EDGE_ADDRESS; fi
        if [[ -n "${EDGE_ADDRESS:-}" ]]; then
          ask DOMAIN_NODE 'Домен Edge-ноды' "$DOMAIN_REALITY" validate_domain
          : # SECRET_KEY fetched automatically from /api/keygen
        fi
      fi
      ;;
    edge)
      ask PANEL_IP 'IP панели' '' validate_ip
      ask DOMAIN_REALITY 'Домен REALITY' '' validate_domain
      ask ADMIN_EMAIL 'Email для сертификата ACME' '' validate_email
      ask NODE_SECRET_KEY 'SECRET_KEY ноды' ''
      ;;
    *) die "Неизвестный режим: $mode";;
  esac
}

usage(){
  cat <<EOF2
Remnawave Manager $VERSION — русская production-версия

Установка:
  $0 install single
  $0 install panel
  $0 install edge

Один VDS:
  $0 install single --yes DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com

Два VDS:
  $0 install panel --yes DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com DOMAIN_REALITY=reality.example.com EDGE_ADDRESS=203.0.113.20 ADMIN_EMAIL=admin@example.com
  $0 install edge --yes PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY='секрет_ноды'

Параметры:
  --dry-run             показать план без изменений
  --yes                 не задавать интерактивных вопросов
  --hysteria2            установить отдельный sing-box Hysteria2 на UDP/8443
  --monitoring           установить Prometheus, node-exporter и cAdvisor
  --telegram-alerts      включить уведомления о сбоях через Telegram
  --no-bbr               оставить стандартный TCP congestion control вместо BBR
  --disable-ipv6         отключить IPv6 через sysctl
  --selfsteal-template N базовый шаблон маскировочного сайта: simple|business|nothing
  --xray-core SOURCE     установить дополнительное ядро: official|joly
  --admin-ip IP          разрешить SSH только с указанного IPv4
  --backup-remote NAME   зашифрованная удалённая копия через rclone + age

Диагностика и обслуживание:
  $0 status
  $0 doctor
  $0 backup
  $0 update
  $0 restore FILE
  $0 uninstall

Ядро Xray:
  $0 core-update [КАТАЛОГ_НОДЫ]
  $0 core-restore [КАТАЛОГ_НОДЫ]

Дополнительные upstream-модули:
  $0 addon remnawave   — CLI Panel DigneZzZ
  $0 addon remnanode   — CLI Node DigneZzZ
  $0 addon selfsteal   — 11 шаблонов маскировки
  $0 addon wtm         — WARP/Tor
  $0 addon netbird     — NetBird
  $0 addon egames      — расширенный eGames Manager

Внешний Xray Checker (рекомендуется отдельный VDS):
  $0 checker-install --yes SUBSCRIPTION_URL=https://sub.example.com/sub/ИДЕНТИФИКАТОР
EOF2
}


main(){
  local args=() mode
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|-y) AUTO_YES=1; shift;;
      --dry-run) DRY_RUN=1; shift;;
      --hysteria2) HYSTERIA2=1; shift;;
      --monitoring) MONITORING=1; shift;;
      --telegram-alerts) TELEGRAM_ALERTS=1; shift;;
      --no-bbr) BBR=0; shift;;
      --disable-ipv6) DISABLE_IPV6=1; shift;;
      --selfsteal-template) SELFSTEAL=1; SELFSTEAL_TEMPLATE="${2:?}"; shift 2;;
      --xray-core) XCORE_SOURCE="${2:?}"; shift 2;;
      --admin-ip) ADMIN_IP="${2:?}"; shift 2;;
      --backup-remote) BACKUP_REMOTE="${2:?}"; shift 2;;
      *=*) export "$1"; shift;;
      *) args+=("$1"); shift;;
    esac
  done
  set -- "${args[@]}"
  case "${1:-install}" in
    install)
      require_root; mkdir -p "$BACKUP_BASE"; touch "$LOG"; chmod 600 "$LOG"
      mode="${2:-${MODE:-single}}"
      if [[ -z "${MODE:-}" && "$mode" == single && -n "${EDGE_ADDRESS:-}" ]]; then mode=panel; fi
      wizard "$mode"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "ПРОБНЫЙ ЗАПУСК: режим=$mode panel=${DOMAIN_PANEL:-} sub=${DOMAIN_SUB:-} reality=${DOMAIN_REALITY:-} hysteria2=$HYSTERIA2 monitoring=$MONITORING telegram=$TELEGRAM_ALERTS bbr=$BBR ipv6_отключён=$DISABLE_IPV6"
        exit 0
      fi
      case "$mode" in single) install_single;; panel) install_panel;; edge) install_edge;; esac
      ;;
    doctor) require_root; doctor;;
    status) status 2>/dev/null || true;;
    backup) require_root; backup;;
    update) require_root; update;;
    core-update) require_root; install_xray_core "${2:-$BASE/node}" "${XCORE_SOURCE:-official}";;
    core-restore) require_root; restore_xray_core "${2:-$BASE/node}";;
    checker-install) require_root; install_xray_checker;;
    addon) require_root; install_upstream_addon "${2:?remnawave|remnanode|selfsteal|wtm|netbird|egames}";;
    restore) require_root; restore "${2:?Укажите архив}";;
    uninstall) require_root; uninstall;;
    help|-h|--help) usage;;
    *) usage; exit 2;;
  esac
}
main "$@"
