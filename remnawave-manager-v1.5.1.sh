#!/usr/bin/env bash
# ==============================================================================
# Remnawave Manager v1.5.1
# Автор: Корги Люси (Corgi Lusi)
#   https://github.com/booarkz-cpu/remnawave-manager
#
# Весь функционал в одном скрипте. Авторство исходных проектов сохранено:
#   • Rezzosoft KVN (Rrezzak09VPN) — мультипротокол ноды
#     https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2
#     Конвертер: https://rezzosoft.ru/converter.html
#   • eGamesAPI — reverse-proxy, панель/нода на разных VDS, SelfSteal
#     https://github.com/eGamesAPI/remnawave-reverse-proxy
#   • DigneZzZ — CLI панели/ноды, бэкапы, ядро Xray, WARP/Tor, NetBird
#     https://github.com/DigneZzZ/remnawave-scripts
#
# Чужой код за свой не выдаём. Модули авторов можно обновить из меню.
# ===============================================================================
set -Eeuo pipefail
IFS=$'\n\t'

VERSION='1.5.1'
CONVERTER_URL='https://rezzosoft.ru/converter.html'
AUTHOR='Корги Люси'
AUTHOR_EN='Corgi Lusi'
PROJECT_URL='https://github.com/booarkz-cpu/remnawave-manager'
GITHUB_REPO='booarkz-cpu/remnawave-manager'
SELF_UPDATE_URL='https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh'
GITHUB_LATEST_API='https://api.github.com/repos/booarkz-cpu/remnawave-manager/releases/latest'
GITHUB_LATEST_HTML='https://github.com/booarkz-cpu/remnawave-manager/releases/latest'
GITHUB_RELEASES_ATOM='https://github.com/booarkz-cpu/remnawave-manager/releases.atom'
JSDELIVR_LATEST_URL='https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@latest/remnawave-manager.sh'
ADDONS_DIR='/opt/remnawave-addons'
BRAND='CorgiLusi'
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
ENABLE_GRPC=0
ENABLE_XHTTP=0
PROTOCOLS_EXPLICIT=0
TELEGRAM_ALERTS=0
BBR=1
DISABLE_IPV6=0
SELFSTEAL=0
XCORE_SOURCE='builtin'
ADMIN_IP=''
FORCE_OS_UPGRADE=0
RW_LANG_SAVED=0
RW_LANG_CLI=0
HYDRATE_QUIET=0
SKIP_UPDATE_CHECK=0
UPDATE_CHECK_TTL=21600
UPDATE_AVAILABLE=0
UPDATE_PROMPT_DONE=0
REMOTE_VERSION=''
TARGET_NODE_UUID=''

# Parse KEY=VALUE without `source`: passwords may contain $ & ` and would abort
# the rest of manager.env (so DOMAIN_* never load) or spawn background jobs.
load_kv_file(){
  local file="$1" line key val
  [[ -r "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    key="${key#"${key%%[![:space:]]*}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    val="${val#\"}"; val="${val%\"}"
    val="${val#\'}"; val="${val%\'}"
    printf -v "$key" '%s' "$val"
    export "$key"
  done < "$file"
}

if [[ -r "$ENV_FILE" ]]; then
  if grep -q '^RW_LANG=' "$ENV_FILE" 2>/dev/null; then RW_LANG_SAVED=1; fi
  load_kv_file "$ENV_FILE"
fi

# Logs stay plain-text. Interactive menu may use ANSI when stdout is a TTY.
C_GREEN=''; C_RED=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_BOLD=''; C_RESET=''
U_RESET=''; U_BOLD=''; U_DIM=''; U_GREEN=''; U_RED=''; U_YELLOW=''; U_CYAN=''; U_BLUE=''; U_MAGENTA=''; U_SKY=''

log(){
  local msg="[$(date '+%F %T')] $*"
  mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
  if [[ -w "$(dirname "$LOG")" ]]; then
    echo "$msg" | tee -a "$LOG" 2>/dev/null || printf '%s\n' "$msg"
  else
    printf '%s\n' "$msg"
  fi
}
ok(){ log "${C_GREEN}✓${C_RESET} $*"; }
warn(){ log "${C_YELLOW}⚠${C_RESET} $*"; }
die(){ trap - ERR; log "${C_RED}✗${C_RESET} $*"; exit 1; }

normalize_lang(){
  local v="${1:-}"
  v="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  case "$v" in
    en|eng|english|en_us|en-us|en_gb|en-gb) printf 'en' ;;
    ru|rus|russian|ru_ru|ru-ru) printf 'ru' ;;
    *) return 1 ;;
  esac
}

init_ui_colors(){
  U_RESET=''; U_BOLD=''; U_DIM=''; U_GREEN=''; U_RED=''; U_YELLOW=''; U_CYAN=''; U_BLUE=''; U_MAGENTA=''; U_SKY=''
  [[ -t 1 ]] || return 0
  case "${TERM:-dumb}" in dumb|unknown|'') return 0 ;; esac
  U_RESET=$'\033[0m'
  U_BOLD=$'\033[1m'
  U_DIM=$'\033[2m'
  U_GREEN=$'\033[32m'
  U_RED=$'\033[31m'
  U_YELLOW=$'\033[33m'
  U_CYAN=$'\033[38;5;45m'
  U_BLUE=$'\033[38;5;39m'
  U_SKY=$'\033[38;5;117m'
  U_MAGENTA=$'\033[38;5;33m'
}

init_ui_lang(){
  local n
  if n="$(normalize_lang "${RW_LANG:-}")"; then
    RW_LANG="$n"
  elif n="$(normalize_lang "${LC_ALL:-}")"; then
    RW_LANG="$n"
  elif n="$(normalize_lang "${LANG%%.*}")"; then
    RW_LANG="$n"
  else
    RW_LANG=ru
  fi
  init_ui_colors
}

# UI catalog. Keys stay stable; %s/%d are printf placeholders.
t(){
  local k="$1"; shift || true
  local s=""
  if [[ "${RW_LANG:-ru}" == en ]]; then
    case "$k" in
      err_line) s='Error at line %s (code %s). See %s' ;;
      err_root) s='Need root. The script re-runs via sudo by itself; install sudo or use a root shell.' ;;
      elevate_hint) s='Raising privileges (no need to type sudo yourself).' ;;
      err_yes_var) s='--yes requires %s.' ;;
      err_invalid) s='Invalid value for %s: %s' ;;
      err_unknown_mode) s='Unknown mode: %s' ;;
      err_unknown_item) s='Unknown menu item.' ;;
      err_cancelled) s='Cancelled.' ;;
      err_repair_no_install) s='No Remnawave install found (no docker-compose, nginx vhost or panel .env). Use menu 1/2/3, or pass DOMAIN_PANEL= DOMAIN_SUB= DOMAIN_REALITY=.' ;;
      recover_domains) s='Restored domains: panel=%s  sub=%s  reality=%s' ;;
      err_restore_arg) s='Specify a backup archive.' ;;
      err_addon) s='Add-on: remnawave|remnanode|selfsteal|wtm|netbird|egames' ;;
      lang_set) s='Interface language: English' ;;
      lang_title) s='Language / Язык' ;;
      lang_en) s='English' ;;
      lang_ru) s='Русский' ;;
      prompt_choice) s='Choice: ' ;;
      prompt_enter) s='Press Enter to return to the menu...' ;;
      prompt_edge_ip) s='Node IP (Enter — add the node later): ' ;;
      prompt_addon) s='Add-on: ' ;;
      prompt_restore) s='Backup archive path: ' ;;
      prompt_logs) s='Container name (Enter — list): ' ;;
      prompt_core) s='Xray core: 1) install official  2) restore builtin  [1]: ' ;;
      prompt_uninstall) s='Type DELETE to confirm uninstall: ' ;;
      prompt_protocols) s='Your choice [5]: ' ;;
      dry_run) s='DRY RUN: mode=%s panel=%s sub=%s reality=%s hysteria2=%s grpc=%s xhttp=%s' ;;
      ask_panel) s='Panel domain' ;;
      ask_sub) s='Subscription page domain' ;;
      ask_reality) s='REALITY SNI domain' ;;
      ask_email) s='Email for ACME certificate' ;;
      ask_node_domain) s='Edge node domain' ;;
      ask_panel_ip) s='Panel IP' ;;
      ask_secret) s='Node SECRET_KEY from /opt/remnawave/credentials.txt on the panel server' ;;
      proto_title) s='Transports (bound to the panel via API, no manual UI edits):' ;;
      proto_1) s='  [1] Reality only' ;;
      proto_2) s='  [2] Reality + Hysteria2 (UDP/443)' ;;
      proto_3) s='  [3] Reality + gRPC (TCP/8443)' ;;
      proto_4) s='  [4] Reality + xHTTP (TCP/4443)' ;;
      proto_5) s='  [5] all: Reality + Hysteria2 + gRPC + xHTTP  (default)' ;;
      menu_header) s='Corgi Lusi  ·  %s' ;;
      menu_author) s='Author: Corgi Lusi' ;;
      menu_modules) s='Modules: Rezzosoft · eGames · DigneZzZ (authorship kept)' ;;
      menu_langline) s='English  ·  item 22 → Русский' ;;
      menu_converter) s='converter (optional): %s' ;;
      menu_sec_install) s='Install' ;;
      menu_sec_ops) s='Operate' ;;
      menu_sec_extra) s='More' ;;
      menu_hint) s='  0 exit   ·   22 language   ·   25 transports   ·   26 script   ·   28 users   ·   29 nodes   ·   31 certs' ;;
      menu_cert) s='cert %s: %s days' ;;
      menu_cert_na) s='cert: no Let’s Encrypt files yet' ;;
      menu_cert_soon) s='cert %s: %s days (renew soon)' ;;
      menu_health_na) s='not installed' ;;
      menu_proto) s='transports: %s' ;;
      m1) s='Full install' ;;
      d1) s='Panel + node on one VPS, nginx SNI, Corgi, certs, API bind' ;;
      m2) s='Panel only' ;;
      d2) s='Panel + subscription HTTPS; EDGE_ADDRESS registers the node' ;;
      m3) s='Node only' ;;
      d3) s='Host-network remnanode + Reality SNI; SECRET_KEY from the panel' ;;
      m4) s='Auto-bind protocols' ;;
      d4) s='Per-node CorgiLusi profiles, CorgiLusi squad, drop Default-Profile' ;;
      m5) s='Status' ;;
      d5) s='Containers, nginx, fail2ban, systemd timers' ;;
      m6) s='Doctor' ;;
      d6) s='Local API, :3010, public HTTPS, certs, UDP/TCP listen, node Connected, UFW' ;;
      m7) s='Repair' ;;
      d7) s='Fix nginx headers and subscription 502 without wiping the DB' ;;
      m8) s='Logs' ;;
      d8) s='Follow remnawave / remnanode / subscription-page' ;;
      m9) s='Start (up)' ;;
      d9) s='docker compose up for every Remnawave stack' ;;
      m10) s='Stop (down)' ;;
      d10) s='docker compose down (data is kept)' ;;
      m11) s='Restart' ;;
      d11) s='Restart every Remnawave compose stack' ;;
      m12) s='Backup' ;;
      d12) s='Archive under /var/backups/remnawave' ;;
      m13) s='Restore' ;;
      d13) s='Restore a .tgz or .age archive' ;;
      m14) s='Update' ;;
      d14) s='Backup, pull images, verify panel API' ;;
      m15) s='Uninstall' ;;
      d15) s='Remove services and nginx vhosts; backups stay' ;;
      m16) s='Xray core' ;;
      d16) s='Custom binary or restore the image builtin' ;;
      m17) s='Add-ons' ;;
      d17) s='DigneZzZ CLI, SelfSteal, WARP/Tor, NetBird, eGames proxy' ;;
      m18) s='Stealth login' ;;
      d18) s='Hide /auth/login behind a secret (eGames idea)' ;;
      m19) s='Install CLI' ;;
      d19) s='Copy to /usr/local/bin/remnawave-manager' ;;
      m20) s='Converter' ;;
      d20) s='Optional Rezzosoft JSON helper — not required to bind' ;;
      m21) s='Credits / help' ;;
      d21) s='Authorship and full CLI help' ;;
      m22) s='Language' ;;
      d22) s='English or Русский (saved in manager.env)' ;;
      m23) s='URLs' ;;
      d23) s='Panel, subscription, SNI and CorgiLusi user link (not passwords)' ;;
      m24) s='Author updates' ;;
      d24) s='Refresh Rezzosoft / eGames / DigneZzZ modules (this installer: item 26)' ;;
      m25) s='Node transports' ;;
      d25) s='Add or remove xHTTP, gRPC, Hysteria2 on a node already installed on another VPS' ;;
      m26) s='This script' ;;
      d26) s='Check and install GitHub Latest of this installer (not Docker images)' ;;
      m27) s='Add a node' ;;
      d27) s='Register another node on the panel via API — no OS upgrade, no menu 1' ;;
      m28) s='Users' ;;
      d28) s='List, create, enable/disable, subscription URL — not the admin password' ;;
      m29) s='Node control' ;;
      d29) s='Disable, enable, restart one node, change its address' ;;
      m30) s='Alerts and remote backup' ;;
      d30) s='Telegram enable/test; rclone+age copy off this VPS' ;;
      m31) s='Certificates' ;;
      d31) s='Let’s Encrypt days left, renew now, copy into /dev/shm on the node' ;;
      m32) s='Firewall' ;;
      d32) s='ADMIN_IP allowlist and rebuild UFW' ;;
      nt_title) s='Transports on an already-installed node' ;;
      nt_now) s='Now: %s' ;;
      nt_split) s='Panel: profile, inbounds, hosts, squad via API. Node VPS: then run apply for ports and certs.' ;;
      nt_role_panel) s='This VPS is the panel. API updates the remote node; then run apply on the node.' ;;
      nt_role_edge) s='This VPS is the node. Ports and certs change here; add/remove on the panel first so the profile matches.' ;;
      nt_role_single) s='Panel and node are on this VPS — API and ports are applied together.' ;;
      nt_1) s='  [1] Add Hysteria2 (UDP/443 + sing-box UDP/8443)' ;;
      nt_2) s='  [2] Add gRPC (VLESS Reality TCP/8443)' ;;
      nt_3) s='  [3] Add xHTTP (VLESS Reality TCP/4443)' ;;
      nt_4) s='  [4] Add all three (keep Reality)' ;;
      nt_5) s='  [5] Remove Hysteria2' ;;
      nt_6) s='  [6] Remove gRPC' ;;
      nt_7) s='  [7] Remove xHTTP' ;;
      nt_8) s='  [8] Remove all three (Reality only)' ;;
      nt_9) s='  [9] Apply on THIS server (node: UFW, certs, Hysteria2 stack)' ;;
      nt_0) s='  [0] Back to node list' ;;
      nt_q) s='  [q] Main menu' ;;
      nt_panel_hint) s='Panel side done. On the NODE server run: bash remnawave-manager.sh node-transports apply' ;;
      nt_edge_ok) s='Local node ports/certs applied. Change the profile on the panel (menu 25 or node-transports add|remove).' ;;
      nt_done) s='Node transports: %s' ;;
      nt_pruned) s='Removed host «%s» (%s).' ;;
      nt_local) s='Local node: UFW, Hysteria2 stack and /dev/shm certs synced.' ;;
      nt_hy2_off) s='Hysteria2 stack and UDP ports removed on this server.' ;;
      help_nt) s='Node transports (already-installed node, including another VPS):' ;;
      help_nt_add) s='  %s node-transports add grpc|xhttp|hysteria2|all [uuid]' ;;
      help_nt_rm) s='  %s node-transports remove grpc|xhttp|hysteria2|all [uuid]' ;;
      help_nt_apply) s='  %s node-transports apply         on the node VPS: ports, certs, Hysteria2' ;;
      help_nt_real) s='  %s node-transports reality-only  drop extras, keep Reality' ;;
      err_nt_proto) s='Unknown transport: %s (grpc|xhttp|hysteria2|all)' ;;
      err_nt_cmd) s='node-transports: add|remove|apply|reality-only|menu' ;;
      m0) s='Exit' ;;
      existing_title) s='Remnawave is already installed on this VPS.' ;;
      existing_1) s='  1) Repair nginx + subscription page (recommended for HTTP 502)' ;;
      existing_2) s='  2) Re-bind protocols via API (no panel edits)' ;;
      existing_3) s='  3) Full reinstall (keeps DB/env unless you uninstall first)' ;;
      existing_0) s='  0) Cancel' ;;
      skip_upgrade) s='Skipping apt full-upgrade (already installed). Pass --os-upgrade to force it.' ;;
      urls_title) s='Public URLs (passwords stay in %s)' ;;
      wait_sub_try) s='Subscription page on :3010 not ready yet (try %s/%s, HTTP %s).' ;;
      wait_sub_fail) s='Subscription page still not answering on :3010. Run menu item 7 (repair) if https://sub-domain returns 502.' ;;
      help_urls) s='  %s urls | health        panel/sub/SNI URLs and public HTTPS check' ;;
      help_os) s='  --os-upgrade       apt full-upgrade during install (skipped if already installed)' ;;
      help_menu) s='No arguments open the interactive menu with descriptions of every function.' ;;
      help_priv) s='Do not prefix the command with sudo — the script raises root itself. --help stays unprivileged.' ;;
      addon_a) s='  a) DigneZzZ remnawave CLI — official-style panel helper' ;;
      addon_b) s='  b) DigneZzZ remnanode CLI — node helper' ;;
      addon_c) s='  c) SelfSteal templates' ;;
      addon_d) s='  d) WARP/Tor (wtm)' ;;
      addon_e) s='  e) NetBird' ;;
      addon_f) s='  f) eGames reverse-proxy installer' ;;
      logs_hint) s='Specify a container: remnawave-manager.sh logs remnawave' ;;
      services_restarted) s='Services restarted.' ;;
      credits_title) s='Credits' ;;
      credits_owner) s='  Author: Corgi Lusi (Корги Люси)  ·  %s' ;;
      credits_repo) s='  %s' ;;
      credits_added) s='Bundled scripts and features (original authorship kept)' ;;
      credits_rez) s='  • Rezzosoft KVN — Reality / Hysteria2 / gRPC / xHTTP node prep' ;;
      credits_conv) s='    Config converter (optional): %s' ;;
      credits_eg) s='  • eGamesAPI remnawave-reverse-proxy — split panel/node, SelfSteal, Cloudflare DNS' ;;
      credits_dig) s='  • DigneZzZ remnawave-scripts — CLI, backups, Xray core, WARP/Tor, NetBird' ;;
      credits_refresh) s='  Menu 24 / `community-update` downloads the authors’ originals without claiming them.' ;;
      comm_title) s='Updates from original authors' ;;
      comm_keep) s='Authorship is kept. We do not claim these scripts as ours.' ;;
      comm_1) s='  1) Refresh all author modules (download only)' ;;
      comm_2) s='  2) Update this Corgi Lusi script from GitHub Latest' ;;
      comm_3) s='  3) Check for a script update (GitHub Latest, no download)' ;;
      comm_0) s='  0) Back' ;;
      comm_done) s='Author modules refreshed. Credits: %s' ;;
      self_ok) s='This script was updated from GitHub Latest. Restarting…' ;;
      upd_available) s='Update available: %s (this script is %s).' ;;
      upd_current) s='This script is up to date (%s).' ;;
      upd_prompt) s='Install GitHub Latest now? [Y/n]: ' ;;
      upd_skip) s='Skipped. Later: menu 26 or bash remnawave-manager.sh self-update' ;;
      upd_fail) s='Could not reach GitHub Latest (network). Try again later.' ;;
      upd_cached) s='Live GitHub check failed. Last known Latest: %s' ;;
      upd_menu) s='update: %s available — item 26 or self-update' ;;
      upd_ok_line) s='script: up to date (%s)' ;;
      help_community) s='  %s community-update   refresh DigneZzZ / eGames modules (authorship kept)' ;;
      help_self) s='  %s self-update        replace this script with GitHub Latest' ;;
      help_check) s='  %s check-update [--apply]  check GitHub Latest (optional install)' ;;
      help_noupdate) s='  --no-update-check   do not query GitHub when opening the menu' ;;
      help_version) s='  %s --version            print this script version (no sudo)' ;;
      help_addnode) s='  %s add-node            register a node on the panel (no apt full-upgrade)' ;;
      help_users) s='  %s users list|create|enable|disable|sub   panel users (sub URL, not admin password)' ;;
      help_nctl) s='  %s nodes disable|enable|restart|address   one node by UUID (restart also: all)' ;;
      help_tg) s='  %s telegram enable|disable|test' ;;
      help_bremote) s='  %s backup-remote [rclone:path]   enable or run encrypted offsite copy' ;;
      help_certs) s='  %s certs [renew]        show days left; renew = certbot now' ;;
      help_fw) s='  %s firewall [IPv4]      show UFW; optional new ADMIN_IP then rebuild' ;;
      help_admin) s='  %s admin-login [SHOW]   print panel login once (SHOW; not written to the log)' ;;
      unknown_cmd) s='Unknown command: %s' ;;
      unknown_cmd_hint) s='Full list: %s --help. If you meant check-update on an old copy, run self-update instead of expecting the whole help dump.' ;;
      unknown_cmd_self) s='Install GitHub Latest: %s self-update' ;;
      nt_pick_title) s='Which node?' ;;
      nt_pick_all) s='  [0] All nodes' ;;
      nt_pick_none) s='No nodes in the API yet. Paste a UUID, 0 for all, or q for the main menu.' ;;
      nt_pick_uuid) s='Number from the list, paste a UUID, 0 = all, q = main menu.' ;;
      nt_selected) s='Node: %s (%s)' ;;
      nt_all) s='all nodes' ;;
      prompt_nt_node) s='Node (number / UUID / 0 = all / q = menu): ' ;;
      nt_next_title) s='Next: apply on the NODE VPS (this server only updated the panel API)' ;;
      nt_next_one) s='  Target node UUID: %s' ;;
      nt_next_all) s='  Target: all nodes' ;;
      nt_next_cmd) s='  On the NODE:  bash remnawave-manager.sh node-transports apply' ;;
      err_need_panel) s='Run this on the panel VPS (menu 27–32), not on a node-only server.' ;;
      usr_title) s='Users' ;;
      usr_1) s='  [1] List' ;;
      usr_2) s='  [2] Create' ;;
      usr_3) s='  [3] Enable' ;;
      usr_4) s='  [4] Disable' ;;
      usr_5) s='  [5] Show subscription URL' ;;
      usr_0) s='  [0] Back' ;;
      usr_empty) s='No users in the API yet.' ;;
      usr_prompt) s='Username (3–32 letters/digits ._-): ' ;;
      usr_pick) s='User (number / UUID / username / q): ' ;;
      usr_ok) s='User %s  %s  %s' ;;
      usr_created) s='Created %s. Subscription: %s' ;;
      usr_status) s='User %s → %s' ;;
      usr_sub) s='Subscription (not the admin password): %s' ;;
      usr_bad) s='Bad username. Use 3–32 characters: A–Z a–z 0–9 . _ -' ;;
      nctl_title) s='Node control' ;;
      nctl_1) s='  [1] List' ;;
      nctl_2) s='  [2] Restart' ;;
      nctl_3) s='  [3] Disable' ;;
      nctl_4) s='  [4] Enable' ;;
      nctl_5) s='  [5] Change address (IP or hostname)' ;;
      nctl_0) s='  [0] Back' ;;
      nctl_need) s='Pick one node (not 0 = all).' ;;
      nctl_addr) s='New node address (IPv4 or hostname): ' ;;
      nctl_ok) s='Node %s: %s' ;;
      nctl_restarted) s='Restarted node %s' ;;
      nctl_addr_ok) s='Node %s address → %s' ;;
      alb_title) s='Alerts and remote backup' ;;
      alb_tg) s='Telegram: %s  chat %s' ;;
      alb_tg_off) s='Telegram: off' ;;
      alb_1) s='  [1] Enable Telegram (bot token + chat id)' ;;
      alb_2) s='  [2] Send a test message' ;;
      alb_3) s='  [3] Disable Telegram alerts' ;;
      alb_4) s='  [4] Set rclone remote and enable the 02:00 timer' ;;
      alb_5) s='  [5] Run encrypted remote backup now' ;;
      alb_6) s='  [6] Disable the remote-backup timer' ;;
      alb_0) s='  [0] Back' ;;
      alb_token) s='Bot token (not logged): ' ;;
      alb_chat) s='Chat id: ' ;;
      alb_thread) s='Thread id (empty = none): ' ;;
      alb_remote) s='rclone destination (e.g. b2:bucket/remnawave): ' ;;
      alb_on) s='on' ;;
      alb_test_ok) s='Test message sent.' ;;
      alb_test_fail) s='Telegram did not accept the message. Check token and chat id.' ;;
      alb_off) s='Telegram alerts disabled (token kept on disk).' ;;
      alb_remote_ok) s='Remote backup timer: daily 02:00 → %s' ;;
      alb_remote_run) s='Remote backup finished.' ;;
      alb_remote_off) s='Remote-backup timer disabled.' ;;
      alb_need_remote) s='Set BACKUP_REMOTE first (menu 30 → 4).' ;;
      crt_title) s='Certificates' ;;
      crt_1) s='  [1] Show days left' ;;
      crt_2) s='  [2] Renew now (certbot renew)' ;;
      crt_3) s='  [3] Force-renew panel / sub / Reality' ;;
      crt_4) s='  [4] Copy certs into /dev/shm (Hysteria2 on this server)' ;;
      crt_0) s='  [0] Back' ;;
      crt_renew_ok) s='certbot renew finished; nginx reloaded.' ;;
      crt_force_ok) s='Force-renewed %s' ;;
      fw_title) s='Firewall' ;;
      fw_ip) s='ADMIN_IP now: %s' ;;
      fw_ip_any) s='ADMIN_IP now: (any — SSH is not locked to one IPv4)' ;;
      fw_1) s='  [1] Show ufw status' ;;
      fw_2) s='  [2] Set ADMIN_IP and rebuild UFW' ;;
      fw_3) s='  [3] Clear ADMIN_IP and rebuild (SSH from any IPv4)' ;;
      fw_4) s='  [4] Rebuild UFW with current flags' ;;
      fw_0) s='  [0] Back' ;;
      fw_ask_ip) s='Admin IPv4 (SSH allowlist): ' ;;
      fw_cleared) s='ADMIN_IP cleared. SSH is allowed from any IPv4 on the SSH port.' ;;
      fw_rebuilt) s='UFW rebuilt.' ;;
      adm_ask) s='Type SHOW to print the panel login once (not written to the log). Anything else cancels: ' ;;
      adm_login) s='Panel login (once, not logged)' ;;
      adm_user) s='  Username: %s' ;;
      adm_pass) s='  Password: %s' ;;
      adm_url) s='  URL:      https://%s/auth/login' ;;
      adm_cancel) s='Cancelled. Panel login was not printed.' ;;
      adm_missing) s='No admin username/password on this VPS. Check %s (do not paste it into chats).' ;;
      addn_title) s='Add a node to the panel' ;;
      addn_need_panel) s='This VPS is not the panel. Register the node from the panel server (menu 27 / add-node).' ;;
      addn_addr) s='Node IP or hostname' ;;
      addn_name) s='Node name in the panel' ;;
      addn_ok) s='Node %s registered at %s. On the NODE VPS: bash remnawave-manager.sh install node' ;;
      addn_secret) s='SECRET_KEY for the node VPS is in %s (Node secret).' ;;
      su_1) s='  [1] Check GitHub Latest again' ;;
      su_2) s='  [2] Install GitHub Latest now' ;;
      su_0) s='  [0] Back' ;;
      pf_title) s='Preflight' ;;
      pf_port_busy) s='Port %s/%s is already in use. Free it before a fresh install.' ;;
      pf_port_ok) s='Port %s/%s is free' ;;
      pf_disk_low) s='Less than %s GB free on / (%s). Install may fail.' ;;
      pf_disk_ok) s='Disk on /: %s free' ;;
      pf_docker_ok) s='Docker: %s' ;;
      pf_docker_miss) s='Docker is not installed yet (install_base will add it).' ;;
      pf_ok) s='Preflight passed.' ;;
      err_os_release) s='Cannot read /etc/os-release.' ;;
      err_os) s='Ubuntu/Debian required, found: %s' ;;
      pkg_installing) s='Installing system packages...' ;;
      os_upgrading) s='Running a full OS upgrade...' ;;
      os_reboot) s='OS upgrade finished; a reboot is needed for a new kernel. The installer will not reboot this VPS.' ;;
      os_done) s='OS upgrade finished; reboot is not required.' ;;
      pkg_ok) s='Base packages installed.' ;;
      err_compose) s='Docker Compose plugin not found.' ;;
      fw_ok) s='UFW enabled.' ;;
      err_panel_ip) s='PANEL_IP is invalid.' ;;
      err_node_inbound) s='No inbound UUID for profile %s.' ;;
      node_updated) s='Node %s updated: profile %s, inbounds bound.' ;;
      node_created) s='Node %s created with profile %s (%s).' ;;
      err_node_create) s='Node was not created.' ;;
      bind_ready) s='Bind complete: squad %s, per-node profile, Default-Profile removed. No panel edits.' ;;
      err_host_addr) s='Could not determine Host address.' ;;
      err_host_empty) s='Host address is empty.' ;;
      err_host_tag) s='No inbound UUID for %s' ;;
      err_host_create) s='Host «%s» was not created.' ;;
      err_admin_pw) s='ADMIN_PASSWORD: at least 24 characters, upper, lower and a digit.' ;;
      err_download) s='Could not download %s' ;;
      err_syntax) s='Downloaded script failed bash -n.' ;;
      cli_ok) s='CLI installed: %s  (run without sudo and without args to open the menu)' ;;
      single_ok) s='Single VPS installed.' ;;
      panel_ok) s='Panel VPS installed.' ;;
      edge_ok) s='Node on a separate server is up. Node card, inbound, Host and squad are created by API on the panel (install panel / item 25 / node-transports) — no panel UI.' ;;
      repair_ok) s='Nginx, proxy headers, subscription-page and SelfSteal site updated. Check panel, subscription and SNI.' ;;
      uninst_ok) s='Remnawave services removed; backups kept.' ;;
      backup_ok) s='Backup: %s' ;;
      err_backup) s='Backup helper is not installed yet. Finish install first, or restore from an existing backup.' ;;
      err_file) s='File not found: %s' ;;
      restore_ok) s='Restore finished, including PostgreSQL dump if the archive had one.' ;;
      update_ok) s='Update finished; a backup was taken and the panel API was checked.' ;;
      err_update) s='Update cancelled.' ;;
      doc_script) s='This script: %s' ;;
      doc_latest) s='GitHub Latest (cache): %s' ;;
      doc_latest_newer) s='GitHub Latest (cache): %s — newer; item 26 or self-update' ;;
      doc_latest_na) s='GitHub Latest: not checked yet' ;;
      doc_certs) s='Let'\''s Encrypt certificates' ;;
      doc_cert_ok) s='%s: valid, %s days left' ;;
      doc_cert_soon) s='%s: expires in %s days' ;;
      doc_cert_gone) s='%s: certificate missing' ;;
      doc_listen) s='Listen sockets' ;;
      doc_listen_ok) s='%s/%s listening' ;;
      doc_listen_miss) s='%s/%s not listening' ;;
      doc_nodes) s='Nodes (API)' ;;
      doc_node_none) s='No nodes in the API yet' ;;
      doc_node_na) s='Nodes: API unavailable (run on the panel)' ;;
      doc_connected) s='Connected' ;;
      doc_disconnected) s='not Connected' ;;
      done_title) s='INSTALL COMPLETE' ;;
      done_note) s='Profile, inbounds, nodes, hosts and squad are bound via API. No panel or converter edits.' ;;
      done_secrets) s='Secrets:' ;;
      done_delete) s='Delete credentials.txt after you have saved the secrets.' ;;
      status_title) s='=== Remnawave status %s ===' ;;
      help_title) s='Corgi Lusi · Remnawave Manager %s (English UI)' ;;
      help_menu) s='No arguments open the interactive menu with descriptions of every function.' ;;
      help_install) s='Install:' ;;
      help_single) s='  %s install single          panel + node on one server' ;;
      help_panel) s='  %s install panel           panel only; nodes connect later' ;;
      help_node) s='  %s install node            node on a separate server (alias: edge)' ;;
      help_one) s='One VPS:' ;;
      help_two) s='Two VPS:' ;;
      help_proto) s='Protocols (all by default; bound via API, no panel UI):' ;;
      help_all) s='  --all-protocols   Reality + Hysteria2 + gRPC + xHTTP (default)' ;;
      help_real) s='  --reality-only    VLESS Reality only' ;;
      help_hy2) s='  --hysteria2       Hysteria2 (Xray UDP/443 + sing-box UDP/8443)' ;;
      help_grpc) s='  --grpc            VLESS gRPC + Reality TCP/8443' ;;
      help_xhttp) s='  --xhttp           VLESS xHTTP + Reality TCP/4443' ;;
      help_bind) s='  %s protocols      refresh profile and re-bind nodes/hosts/squad' ;;
      help_bind2) s='  %s bind           same as protocols' ;;
      help_ops) s='Maintenance:' ;;
      help_ops_line) s='  %s menu | status | doctor | repair | backup | restore FILE | update | uninstall' ;;
      help_ops2) s='  %s up | down | restart | logs [container]' ;;
      help_core) s='  %s core-update | core-restore' ;;
      help_stealth) s='  %s stealth                hidden panel login URL (eGames idea)' ;;
      help_cli) s='  %s install-script         remnawave-manager command in /usr/local/bin' ;;
      help_lang) s='  %s --lang en|ru           interface language (saved in manager.env)' ;;
      help_addons) s='Add-ons (original authorship kept):' ;;
      help_addon_line) s='  %s addon remnawave|remnanode|selfsteal|wtm|netbird|egames' ;;
      help_conv) s='Rezzosoft KVN converter (optional):' ;;
      *) s="$k" ;;
    esac
  else
    case "$k" in
      err_line) s='Ошибка в строке %s (код %s). Смотрите %s' ;;
      err_root) s='Нужны права root. Скрипт сам перезапускается через sudo; установите sudo или войдите как root.' ;;
      elevate_hint) s='Поднимаю права (sudo в команде писать не нужно).' ;;
      err_yes_var) s='--yes требует параметр %s.' ;;
      err_invalid) s='Некорректное значение для %s: %s' ;;
      err_unknown_mode) s='Неизвестный режим: %s' ;;
      err_unknown_item) s='Неизвестный пункт.' ;;
      err_cancelled) s='Отменено.' ;;
      err_repair_no_install) s='Установка Remnawave не найдена (нет docker-compose, nginx vhost или .env панели). Пункт 1/2/3 или передайте DOMAIN_PANEL= DOMAIN_SUB= DOMAIN_REALITY=.' ;;
      recover_domains) s='Домены восстановлены: panel=%s  sub=%s  reality=%s' ;;
      err_restore_arg) s='Укажите архив.' ;;
      err_addon) s='Модуль: remnawave|remnanode|selfsteal|wtm|netbird|egames' ;;
      lang_set) s='Язык интерфейса: русский' ;;
      lang_title) s='Язык / Language' ;;
      lang_en) s='English' ;;
      lang_ru) s='Русский' ;;
      prompt_choice) s='Выбор: ' ;;
      prompt_enter) s='Enter — вернуться в меню...' ;;
      prompt_edge_ip) s='IP ноды (Enter — добавить ноду позже): ' ;;
      prompt_addon) s='Модуль: ' ;;
      prompt_restore) s='Путь к архиву backup: ' ;;
      prompt_logs) s='Имя контейнера (Enter — список): ' ;;
      prompt_core) s='Ядро Xray: 1) поставить официальное  2) вернуть штатное  [1]: ' ;;
      prompt_uninstall) s='Введите DELETE для подтверждения: ' ;;
      prompt_protocols) s='Ваш выбор [5]: ' ;;
      dry_run) s='ПРОБНЫЙ ЗАПУСК: режим=%s panel=%s sub=%s reality=%s hysteria2=%s grpc=%s xhttp=%s' ;;
      ask_panel) s='Домен Panel' ;;
      ask_sub) s='Домен Subscription Page' ;;
      ask_reality) s='Домен SNI для REALITY' ;;
      ask_email) s='Email для сертификата ACME' ;;
      ask_node_domain) s='Домен Edge-ноды' ;;
      ask_panel_ip) s='IP панели' ;;
      ask_secret) s='SECRET_KEY ноды из /opt/remnawave/credentials.txt на сервере панели' ;;
      proto_title) s='Транспорты (привязка к панели — полностью через API, без ручного редактирования):' ;;
      proto_1) s='  [1] только Reality' ;;
      proto_2) s='  [2] Reality + Hysteria2 (UDP/443)' ;;
      proto_3) s='  [3] Reality + gRPC (TCP/8443)' ;;
      proto_4) s='  [4] Reality + xHTTP (TCP/4443)' ;;
      proto_5) s='  [5] все: Reality + Hysteria2 + gRPC + xHTTP  (по умолчанию)' ;;
      menu_header) s='Корги Люси  ·  %s' ;;
      menu_author) s='Автор: Корги Люси' ;;
      menu_modules) s='Модули: Rezzosoft · eGames · DigneZzZ (авторство сохранено)' ;;
      menu_langline) s='Русский  ·  пункт 22 → English' ;;
      menu_converter) s='конвертер (необязательно): %s' ;;
      menu_sec_install) s='Установка' ;;
      menu_sec_ops) s='Обслуживание' ;;
      menu_sec_extra) s='Ещё' ;;
      menu_hint) s='  0 выход   ·   22 язык   ·   25 транспорты   ·   26 скрипт   ·   28 пользователи   ·   29 ноды   ·   31 сертификаты' ;;
      menu_cert) s='серт. %s: %s дн.' ;;
      menu_cert_na) s='серт.: файлов Let’s Encrypt пока нет' ;;
      menu_cert_soon) s='серт. %s: %s дн. (скоро обновить)' ;;
      menu_health_na) s='не установлено' ;;
      menu_proto) s='транспорты: %s' ;;
      m1) s='Полная установка' ;;
      d1) s='Панель + нода на одном VDS, nginx SNI, Corgi, сертификаты, API' ;;
      m2) s='Только панель' ;;
      d2) s='Панель + подписка HTTPS; EDGE_ADDRESS сразу регистрирует ноду' ;;
      m3) s='Только нода' ;;
      d3) s='remnanode в host-сети + SNI Reality; SECRET_KEY с панели' ;;
      m4) s='Автопривязка протоколов' ;;
      d4) s='Отдельный профиль CorgiLusi на ноду, сквад CorgiLusi, без Default-Profile' ;;
      m5) s='Состояние' ;;
      d5) s='Контейнеры, nginx, fail2ban, systemd-таймеры' ;;
      m6) s='Диагностика' ;;
      d6) s='Локальный API, :3010, публичный HTTPS, сертификаты, UDP/TCP, Connected нод, UFW' ;;
      m7) s='Repair' ;;
      d7) s='Исправить nginx и 502 подписки без удаления БД' ;;
      m8) s='Логи' ;;
      d8) s='Журнал remnawave / remnanode / subscription-page' ;;
      m9) s='Запуск (up)' ;;
      d9) s='docker compose up всех стеков Remnawave' ;;
      m10) s='Стоп (down)' ;;
      d10) s='docker compose down (данные сохраняются)' ;;
      m11) s='Перезапуск' ;;
      d11) s='Перезапуск всех compose-стеков Remnawave' ;;
      m12) s='Backup' ;;
      d12) s='Архив в /var/backups/remnawave' ;;
      m13) s='Restore' ;;
      d13) s='Восстановление из .tgz или .age' ;;
      m14) s='Обновление' ;;
      d14) s='Backup, pull образов, проверка API панели' ;;
      m15) s='Удаление' ;;
      d15) s='Снимает сервисы и nginx vhost; backup остаётся' ;;
      m16) s='Ядро Xray' ;;
      d16) s='Свой бинарник или штатный из образа' ;;
      m17) s='Модули' ;;
      d17) s='CLI DigneZzZ, SelfSteal, WARP/Tor, NetBird, eGames proxy' ;;
      m18) s='Скрытый вход' ;;
      d18) s='Прячет /auth/login за секретом (идея eGames)' ;;
      m19) s='Команда CLI' ;;
      d19) s='Копирует скрипт в /usr/local/bin/remnawave-manager' ;;
      m20) s='Конвертер' ;;
      d20) s='Необязательный JSON Rezzosoft — для привязки не нужен' ;;
      m21) s='Авторство / справка' ;;
      d21) s='Авторы и полная справка CLI' ;;
      m22) s='Язык' ;;
      d22) s='Русский или English (сохраняется в manager.env)' ;;
      m23) s='Адреса' ;;
      d23) s='Панель, подписка, SNI и ссылка CorgiLusi (без паролей)' ;;
      m24) s='Обновления авторов' ;;
      d24) s='Скачать свежие модули Rezzosoft / eGames / DigneZzZ (этот установщик: пункт 26)' ;;
      m25) s='Транспорты ноды' ;;
      d25) s='Добавить или снять xHTTP, gRPC, Hysteria2 на уже установленной ноде (в том числе на другом VDS)' ;;
      m26) s='Этот скрипт' ;;
      d26) s='Проверить и поставить GitHub Latest этого установщика (не Docker-образы)' ;;
      m27) s='Добавить ноду' ;;
      d27) s='Зарегистрировать ещё одну ноду в панели через API — без обновления ОС и без пункта 1' ;;
      m28) s='Пользователи' ;;
      d28) s='Список, создать, вкл/выкл, ссылка подписки — не пароль администратора' ;;
      m29) s='Управление нодами' ;;
      d29) s='Выключить, включить, перезапустить одну ноду, сменить адрес' ;;
      m30) s='Оповещения и удалённый backup' ;;
      d30) s='Telegram вкл/тест; копия rclone+age с этого VDS' ;;
      m31) s='Сертификаты' ;;
      d31) s='Срок Let’s Encrypt, обновить сейчас, скопировать в /dev/shm на ноде' ;;
      m32) s='Файрвол' ;;
      d32) s='Allowlist ADMIN_IP и пересобрать UFW' ;;
      nt_title) s='Транспорты уже установленной ноды' ;;
      nt_now) s='Сейчас: %s' ;;
      nt_split) s='Панель: профиль, inbound’ы, хосты, сквад через API. Нода: затем apply — порты и сертификаты.' ;;
      nt_role_panel) s='Этот VDS — панель. API обновит удалённую ноду; затем на ноде выполните apply.' ;;
      nt_role_edge) s='Этот VDS — нода. Порты и сертификаты меняются здесь; add/remove сначала на панели, чтобы профиль совпал.' ;;
      nt_role_single) s='Панель и нода на этом VDS — API и порты применяются вместе.' ;;
      nt_1) s='  [1] Добавить Hysteria2 (UDP/443 + sing-box UDP/8443)' ;;
      nt_2) s='  [2] Добавить gRPC (VLESS Reality TCP/8443)' ;;
      nt_3) s='  [3] Добавить xHTTP (VLESS Reality TCP/4443)' ;;
      nt_4) s='  [4] Добавить все три (Reality остаётся)' ;;
      nt_5) s='  [5] Удалить Hysteria2' ;;
      nt_6) s='  [6] Удалить gRPC' ;;
      nt_7) s='  [7] Удалить xHTTP' ;;
      nt_8) s='  [8] Удалить все три (оставить только Reality)' ;;
      nt_9) s='  [9] Применить на ЭТОМ сервере (нода: UFW, сертификаты, стек Hysteria2)' ;;
      nt_0) s='  [0] К списку нод' ;;
      nt_q) s='  [q] В главное меню' ;;
      nt_panel_hint) s='Панель готова. На сервере НОДЫ выполните: bash remnawave-manager.sh node-transports apply' ;;
      nt_edge_ok) s='Локальные порты/сертификаты ноды применены. Профиль меняйте на панели (пункт 25 или node-transports add|remove).' ;;
      nt_done) s='Транспорты ноды: %s' ;;
      nt_pruned) s='Хост «%s» удалён (%s).' ;;
      nt_local) s='Локальная нода: UFW, стек Hysteria2 и сертификаты в /dev/shm синхронизированы.' ;;
      nt_hy2_off) s='Стек Hysteria2 и UDP-порты на этом сервере сняты.' ;;
      help_nt) s='Транспорты уже установленной ноды (в том числе на другом VDS):' ;;
      help_nt_add) s='  %s node-transports add grpc|xhttp|hysteria2|all [uuid]' ;;
      help_nt_rm) s='  %s node-transports remove grpc|xhttp|hysteria2|all [uuid]' ;;
      help_nt_apply) s='  %s node-transports apply         на VDS ноды: порты, сертификаты, Hysteria2' ;;
      help_nt_real) s='  %s node-transports reality-only  снять доп. протоколы, оставить Reality' ;;
      err_nt_proto) s='Неизвестный транспорт: %s (grpc|xhttp|hysteria2|all)' ;;
      err_nt_cmd) s='node-transports: add|remove|apply|reality-only|menu' ;;
      m0) s='Выход' ;;
      existing_title) s='Remnawave уже установлен на этом VDS.' ;;
      existing_1) s='  1) Repair nginx + страница подписки (рекомендуется при HTTP 502)' ;;
      existing_2) s='  2) Заново привязать протоколы через API (без правок в панели)' ;;
      existing_3) s='  3) Полная переустановка (БД/env сохраняются, если не делали uninstall)' ;;
      existing_0) s='  0) Отмена' ;;
      skip_upgrade) s='Пропускаем apt full-upgrade (уже установлено). Флаг --os-upgrade принудительно обновляет ОС.' ;;
      urls_title) s='Публичные адреса (пароли остаются в %s)' ;;
      wait_sub_try) s='Страница подписки на :3010 ещё не отвечает (попытка %s/%s, HTTP %s).' ;;
      wait_sub_fail) s='Страница подписки всё ещё не отвечает на :3010. Если https://домен-подписки даёт 502 — пункт 7 (repair).' ;;
      help_urls) s='  %s urls | health        адреса панели/подписки/SNI и проверка HTTPS' ;;
      help_os) s='  --os-upgrade       apt full-upgrade при установке (по умолчанию пропускается, если уже стоит)' ;;
      help_menu) s='Без аргументов открывается меню с описанием всех функций.' ;;
      help_priv) s='Префикс sudo в команде не нужен — скрипт сам поднимает root. --help работает без пароля.' ;;
      addon_a) s='  a) DigneZzZ remnawave CLI — помощник панели' ;;
      addon_b) s='  b) DigneZzZ remnanode CLI — помощник ноды' ;;
      addon_c) s='  c) Шаблоны SelfSteal' ;;
      addon_d) s='  d) WARP/Tor (wtm)' ;;
      addon_e) s='  e) NetBird' ;;
      addon_f) s='  f) Установщик eGames reverse-proxy' ;;
      logs_hint) s='Укажите контейнер: remnawave-manager.sh logs remnawave' ;;
      services_restarted) s='Сервисы перезапущены.' ;;
      credits_title) s='Авторство' ;;
      credits_owner) s='  Автор: Корги Люси (Corgi Lusi)  ·  %s' ;;
      credits_repo) s='  %s' ;;
      credits_added) s='Добавленные скрипты и функции (авторство исходников сохранено)' ;;
      credits_rez) s='  • Rezzosoft KVN — подготовка ноды Reality / Hysteria2 / gRPC / xHTTP' ;;
      credits_conv) s='    Конвертер конфигов (необязательно): %s' ;;
      credits_eg) s='  • eGamesAPI remnawave-reverse-proxy — панель и нода на разных серверах, SelfSteal, Cloudflare DNS' ;;
      credits_dig) s='  • DigneZzZ remnawave-scripts — CLI, бэкапы, ядро Xray, WARP/Tor, NetBird' ;;
      credits_refresh) s='  Пункт 24 / `community-update` скачивает оригиналы авторов, не выдавая их за свои.' ;;
      comm_title) s='Обновления от авторов модулей' ;;
      comm_keep) s='Авторство сохранено. Чужой код за свой не выдаём.' ;;
      comm_1) s='  1) Обновить все модули авторов (только скачать)' ;;
      comm_2) s='  2) Обновить этот скрипт Корги Люси с GitHub Latest' ;;
      comm_3) s='  3) Проверить обновление этого скрипта (GitHub Latest, без скачивания)' ;;
      comm_0) s='  0) Назад' ;;
      comm_done) s='Модули авторов обновлены. Авторство: %s' ;;
      self_ok) s='Скрипт обновлён с GitHub Latest. Перезапуск…' ;;
      upd_available) s='Доступно обновление: %s (сейчас %s).' ;;
      upd_current) s='Скрипт актуален (%s).' ;;
      upd_prompt) s='Установить GitHub Latest сейчас? [Y/n]: ' ;;
      upd_skip) s='Пропущено. Позже: пункт 26 или bash remnawave-manager.sh self-update' ;;
      upd_fail) s='Не удалось связаться с GitHub Latest (сеть). Попробуйте позже.' ;;
      upd_cached) s='Живая проверка GitHub не удалась. Последний известный Latest: %s' ;;
      upd_menu) s='обновление: доступна %s — пункт 26 или self-update' ;;
      upd_ok_line) s='скрипт актуален (%s)' ;;
      help_community) s='  %s community-update   обновить модули DigneZzZ / eGames (авторство сохранено)' ;;
      help_self) s='  %s self-update        заменить этот скрипт на GitHub Latest' ;;
      help_check) s='  %s check-update [--apply]  проверить GitHub Latest (по желанию установить)' ;;
      help_noupdate) s='  --no-update-check   не опрашивать GitHub при открытии меню' ;;
      help_version) s='  %s --version            версия этого скрипта (без sudo)' ;;
      help_addnode) s='  %s add-node            зарегистрировать ноду на панели (без apt full-upgrade)' ;;
      help_users) s='  %s users list|create|enable|disable|sub   пользователи панели (ссылка, не пароль админа)' ;;
      help_nctl) s='  %s nodes disable|enable|restart|address   одна нода по UUID (restart ещё: all)' ;;
      help_tg) s='  %s telegram enable|disable|test' ;;
      help_bremote) s='  %s backup-remote [rclone:path]   включить или сразу сделать шифрованную копию' ;;
      help_certs) s='  %s certs [renew]        срок сертификатов; renew — certbot сейчас' ;;
      help_fw) s='  %s firewall [IPv4]      UFW; необязательно новый ADMIN_IP и пересборка' ;;
      help_admin) s='  %s admin-login [SHOW]   один раз показать вход в панель (слово SHOW; в лог не пишется)' ;;
      unknown_cmd) s='Неизвестная команда: %s' ;;
      unknown_cmd_hint) s='Полный список: %s --help. Если ждали check-update на старой копии — выполните self-update, а не ждите всю справку.' ;;
      unknown_cmd_self) s='Поставить GitHub Latest: %s self-update' ;;
      nt_pick_title) s='Какую ноду?' ;;
      nt_pick_all) s='  [0] Все ноды' ;;
      nt_pick_none) s='В API пока нет нод. Вставьте UUID, 0 — все, q — главное меню.' ;;
      nt_pick_uuid) s='Номер из списка, UUID, 0 = все, q = главное меню.' ;;
      nt_selected) s='Нода: %s (%s)' ;;
      nt_all) s='все ноды' ;;
      prompt_nt_node) s='Нода (номер / UUID / 0 = все / q = меню): ' ;;
      nt_next_title) s='Дальше: apply на VDS НОДЫ (этот сервер обновил только API панели)' ;;
      nt_next_one) s='  UUID ноды: %s' ;;
      nt_next_all) s='  Цель: все ноды' ;;
      nt_next_cmd) s='  На НОДЕ:  bash remnawave-manager.sh node-transports apply' ;;
      err_need_panel) s='Запускайте на VDS панели (пункты 27–32), не на сервере «только нода».' ;;
      usr_title) s='Пользователи' ;;
      usr_1) s='  [1] Список' ;;
      usr_2) s='  [2] Создать' ;;
      usr_3) s='  [3] Включить' ;;
      usr_4) s='  [4] Выключить' ;;
      usr_5) s='  [5] Показать ссылку подписки' ;;
      usr_0) s='  [0] Назад' ;;
      usr_empty) s='В API пока нет пользователей.' ;;
      usr_prompt) s='Имя (3–32 буквы/цифры ._-): ' ;;
      usr_pick) s='Пользователь (номер / UUID / имя / q): ' ;;
      usr_ok) s='Пользователь %s  %s  %s' ;;
      usr_created) s='Создан %s. Подписка: %s' ;;
      usr_status) s='Пользователь %s → %s' ;;
      usr_sub) s='Подписка (не пароль администратора): %s' ;;
      usr_bad) s='Плохое имя. 3–32 символа: A–Z a–z 0–9 . _ -' ;;
      nctl_title) s='Управление нодами' ;;
      nctl_1) s='  [1] Список' ;;
      nctl_2) s='  [2] Перезапустить' ;;
      nctl_3) s='  [3] Выключить' ;;
      nctl_4) s='  [4] Включить' ;;
      nctl_5) s='  [5] Сменить адрес (IP или hostname)' ;;
      nctl_0) s='  [0] Назад' ;;
      nctl_need) s='Выберите одну ноду (не 0 = все).' ;;
      nctl_addr) s='Новый адрес ноды (IPv4 или hostname): ' ;;
      nctl_ok) s='Нода %s: %s' ;;
      nctl_restarted) s='Нода %s перезапущена' ;;
      nctl_addr_ok) s='Нода %s адрес → %s' ;;
      alb_title) s='Оповещения и удалённый backup' ;;
      alb_tg) s='Telegram: %s  чат %s' ;;
      alb_tg_off) s='Telegram: выкл' ;;
      alb_1) s='  [1] Включить Telegram (токен бота + chat id)' ;;
      alb_2) s='  [2] Отправить тест' ;;
      alb_3) s='  [3] Выключить оповещения Telegram' ;;
      alb_4) s='  [4] Указать rclone remote и включить таймер 02:00' ;;
      alb_5) s='  [5] Сделать шифрованную удалённую копию сейчас' ;;
      alb_6) s='  [6] Выключить таймер удалённого backup' ;;
      alb_0) s='  [0] Назад' ;;
      alb_token) s='Токен бота (в лог не пишется): ' ;;
      alb_chat) s='Chat id: ' ;;
      alb_thread) s='Thread id (пусто = нет): ' ;;
      alb_remote) s='Назначение rclone (например b2:bucket/remnawave): ' ;;
      alb_on) s='вкл' ;;
      alb_test_ok) s='Тестовое сообщение отправлено.' ;;
      alb_test_fail) s='Telegram не принял сообщение. Проверьте токен и chat id.' ;;
      alb_off) s='Оповещения Telegram выключены (токен на диске сохранён).' ;;
      alb_remote_ok) s='Таймер удалённого backup: каждый день 02:00 → %s' ;;
      alb_remote_run) s='Удалённый backup выполнен.' ;;
      alb_remote_off) s='Таймер удалённого backup выключен.' ;;
      alb_need_remote) s='Сначала укажите BACKUP_REMOTE (пункт 30 → 4).' ;;
      crt_title) s='Сертификаты' ;;
      crt_1) s='  [1] Показать срок' ;;
      crt_2) s='  [2] Обновить сейчас (certbot renew)' ;;
      crt_3) s='  [3] Принудительно обновить panel / sub / Reality' ;;
      crt_4) s='  [4] Скопировать сертификаты в /dev/shm (Hysteria2 на этом сервере)' ;;
      crt_0) s='  [0] Назад' ;;
      crt_renew_ok) s='certbot renew завершён; nginx перезагружен.' ;;
      crt_force_ok) s='Принудительно обновлён %s' ;;
      fw_title) s='Файрвол' ;;
      fw_ip) s='ADMIN_IP сейчас: %s' ;;
      fw_ip_any) s='ADMIN_IP сейчас: (любой — SSH не привязан к одному IPv4)' ;;
      fw_1) s='  [1] Показать ufw status' ;;
      fw_2) s='  [2] Задать ADMIN_IP и пересобрать UFW' ;;
      fw_3) s='  [3] Снять ADMIN_IP и пересобрать (SSH с любого IPv4)' ;;
      fw_4) s='  [4] Пересобрать UFW с текущими флагами' ;;
      fw_0) s='  [0] Назад' ;;
      fw_ask_ip) s='IPv4 администратора (allowlist SSH): ' ;;
      fw_cleared) s='ADMIN_IP снят. SSH разрешён с любого IPv4 на порту SSH.' ;;
      fw_rebuilt) s='UFW пересобран.' ;;
      adm_ask) s='Чтобы один раз показать вход в панель, напишите SHOW (в лог не попадёт). Иначе отмена: ' ;;
      adm_login) s='Вход в панель (один раз, не логируется)' ;;
      adm_user) s='  Логин:  %s' ;;
      adm_pass) s='  Пароль: %s' ;;
      adm_url) s='  URL:    https://%s/auth/login' ;;
      adm_cancel) s='Отменено. Логин панели не печатали.' ;;
      adm_missing) s='На этом VDS нет логина/пароля админа. Смотрите %s (в чаты не копируйте).' ;;
      addn_title) s='Добавить ноду на панель' ;;
      addn_need_panel) s='Этот VDS не панель. Регистрируйте ноду с сервера панели (пункт 27 / add-node).' ;;
      addn_addr) s='IP или hostname ноды' ;;
      addn_name) s='Имя ноды в панели' ;;
      addn_ok) s='Нода %s зарегистрирована на %s. На VDS НОДЫ: bash remnawave-manager.sh install node' ;;
      addn_secret) s='SECRET_KEY для VDS ноды лежит в %s (Node secret).' ;;
      su_1) s='  [1] Снова проверить GitHub Latest' ;;
      su_2) s='  [2] Установить GitHub Latest сейчас' ;;
      su_0) s='  [0] Назад' ;;
      pf_title) s='Предпроверка' ;;
      pf_port_busy) s='Порт %s/%s уже занят. Освободите его перед новой установкой.' ;;
      pf_port_ok) s='Порт %s/%s свободен' ;;
      pf_disk_low) s='На / меньше %s ГБ свободно (%s). Установка может не пройти.' ;;
      pf_disk_ok) s='Диск /: свободно %s' ;;
      pf_docker_ok) s='Docker: %s' ;;
      pf_docker_miss) s='Docker ещё не установлен (поставит install_base).' ;;
      pf_ok) s='Предпроверка пройдена.' ;;
      err_os_release) s='Не найден /etc/os-release.' ;;
      err_os) s='Нужны Ubuntu/Debian, обнаружено: %s' ;;
      pkg_installing) s='Устанавливаем системные зависимости...' ;;
      os_upgrading) s='Выполняем полное обновление операционной системы...' ;;
      os_reboot) s='Полное обновление ОС завершено; для нового ядра нужна перезагрузка. Установщик сам VDS не перезагружает.' ;;
      os_done) s='Полное обновление операционной системы завершено; перезагрузка не требуется.' ;;
      pkg_ok) s='Базовые пакеты установлены.' ;;
      err_compose) s='Docker Compose plugin не найден.' ;;
      fw_ok) s='UFW включён.' ;;
      err_panel_ip) s='PANEL_IP некорректен.' ;;
      err_node_inbound) s='Нет inbound UUID для профиля %s.' ;;
      node_updated) s='Нода %s обновлена: свой профиль %s, inbound-ы привязаны.' ;;
      node_created) s='Нода %s создана с отдельным профилем %s (%s).' ;;
      err_node_create) s='Node не создан.' ;;
      bind_ready) s='Привязка готова: сквад %s, отдельный профиль на ноду, Default-Profile удалён. Панель править не нужно.' ;;
      err_host_addr) s='Не удалось определить адрес для Host.' ;;
      err_host_empty) s='Адрес Host пустой.' ;;
      err_host_tag) s='Нет inbound UUID для %s' ;;
      err_host_create) s='Host «%s» не создан.' ;;
      err_admin_pw) s='ADMIN_PASSWORD: минимум 24 символа, заглавная, строчная и цифра.' ;;
      err_download) s='Не удалось скачать %s' ;;
      err_syntax) s='Скачанный скрипт не проходит bash -n.' ;;
      cli_ok) s='CLI установлен: %s  (запуск без sudo и без аргументов открывает меню)' ;;
      single_ok) s='Single VDS установлен.' ;;
      panel_ok) s='Panel VDS установлен.' ;;
      edge_ok) s='Нода на отдельном сервере запущена. Карточка Node, inbound, Host и сквад создаются API на сервере панели (install panel / пункт 25 / node-transports) — UI панели не нужен.' ;;
      repair_ok) s='Nginx, proxy-заголовки, subscription-page и маскировочный сайт обновлены. Проверьте панель, подписку и SNI-сайт.' ;;
      uninst_ok) s='Remnawave сервисы удалены; backups сохранены.' ;;
      backup_ok) s='Backup: %s' ;;
      err_backup) s='Backup helper ещё не установлен. Сначала завершите install или выполните restore из существующего backup.' ;;
      err_file) s='Файл не найден: %s' ;;
      restore_ok) s='Restore завершён, включая импорт PostgreSQL dump при наличии в архиве.' ;;
      update_ok) s='Обновление завершено; перед обновлением создан backup и проверен API.' ;;
      err_update) s='Обновление отменено.' ;;
      doc_script) s='Этот скрипт: %s' ;;
      doc_latest) s='GitHub Latest (кэш): %s' ;;
      doc_latest_newer) s='GitHub Latest (кэш): %s — новее; пункт 26 или self-update' ;;
      doc_latest_na) s='GitHub Latest: ещё не проверяли' ;;
      doc_certs) s='Сертификаты Let'\''s Encrypt' ;;
      doc_cert_ok) s='%s: действителен, осталось %s дн.' ;;
      doc_cert_soon) s='%s: истекает через %s дн.' ;;
      doc_cert_gone) s='%s: сертификат отсутствует' ;;
      doc_listen) s='Сокеты прослушивания' ;;
      doc_listen_ok) s='%s/%s слушает' ;;
      doc_listen_miss) s='%s/%s не слушает' ;;
      doc_nodes) s='Ноды (API)' ;;
      doc_node_none) s='В API пока нет нод' ;;
      doc_node_na) s='Ноды: API недоступен (запустите на панели)' ;;
      doc_connected) s='Connected' ;;
      doc_disconnected) s='не Connected' ;;
      done_title) s='УСТАНОВКА ЗАВЕРШЕНА' ;;
      done_note) s='Профиль, inbound'\''ы, ноды, хосты и сквад привязаны через API. Панель и конвертер править не нужно.' ;;
      done_secrets) s='Секреты:' ;;
      done_delete) s='Удалите credentials.txt после сохранения секретов.' ;;
      status_title) s='=== Состояние Remnawave %s ===' ;;
      help_title) s='Корги Люси · Remnawave Manager %s (русский интерфейс)' ;;
      help_menu) s='Без аргументов открывается меню с описанием всех функций.' ;;
      help_install) s='Установка:' ;;
      help_single) s='  %s install single          всё на одном сервере (панель + нода)' ;;
      help_panel) s='  %s install panel           только панель; ноды подключаются отдельно' ;;
      help_node) s='  %s install node            только нода на отдельном сервере (синоним: edge)' ;;
      help_one) s='Один VDS:' ;;
      help_two) s='Два VDS:' ;;
      help_proto) s='Протоколы (по умолчанию все; привязка через API, без правок в панели):' ;;
      help_all) s='  --all-protocols   Reality + Hysteria2 + gRPC + xHTTP (это же значение по умолчанию)' ;;
      help_real) s='  --reality-only    только VLESS Reality' ;;
      help_hy2) s='  --hysteria2       Hysteria2 (Xray inbound UDP/443 + sing-box UDP/8443)' ;;
      help_grpc) s='  --grpc            VLESS gRPC + Reality TCP/8443' ;;
      help_xhttp) s='  --xhttp           VLESS xHTTP + Reality TCP/4443' ;;
      help_bind) s='  %s protocols      обновить профиль и заново привязать ноды/хосты/сквад' ;;
      help_bind2) s='  %s bind           то же, что protocols' ;;
      help_ops) s='Обслуживание:' ;;
      help_ops_line) s='  %s menu | status | doctor | repair | backup | restore FILE | update | uninstall' ;;
      help_ops2) s='  %s up | down | restart | logs [контейнер]' ;;
      help_core) s='  %s core-update | core-restore' ;;
      help_stealth) s='  %s stealth                скрытый URL входа в панель (идея eGames)' ;;
      help_cli) s='  %s install-script         команда remnawave-manager в /usr/local/bin' ;;
      help_lang) s='  %s --lang en|ru           язык интерфейса (сохраняется в manager.env)' ;;
      help_addons) s='Модули (авторство сохранено):' ;;
      help_addon_line) s='  %s addon remnawave|remnanode|selfsteal|wtm|netbird|egames' ;;
      help_conv) s='Конвертер конфигов Rezzosoft KVN (необязательно):' ;;
      *) s="$k" ;;
    esac
  fi
  # shellcheck disable=SC2059
  printf "$s" "$@"
}

# 141 = SIGPIPE from `cmd | head` under pipefail; do not abort the install.
trap 'rc=$?; [[ $rc -eq 141 ]] || die "$(t err_line "${BASH_LINENO[0]:-$LINENO}" "$rc" "$LOG")"' ERR

init_ui_lang

wants_help_only(){
  local a has_check=0 has_apply=0
  for a in "$@"; do
    case "$a" in
      help|-h|--help|--version|-V|version) return 0 ;;
      check-update|check-updates) has_check=1 ;;
      --apply|apply) has_apply=1 ;;
    esac
  done
  [[ $has_check -eq 1 && $has_apply -eq 0 ]]
}

script_path(){
  local p
  p="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)"
  if [[ -n "$p" && -f "$p" ]]; then
    printf '%s' "$p"
    return 0
  fi
  printf '%s' "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
}

# Re-exec via sudo so the user never has to type `sudo bash …`.
# `--help` stays unprivileged (no password prompt just to read usage).
elevate_if_needed(){
  [[ ${EUID:-$(id -u)} -eq 0 ]] && return 0
  wants_help_only "$@" && return 0
  [[ "${RW_ELEVATED:-0}" == 1 ]] && die "$(t err_root)"
  local self
  self="$(script_path)"
  [[ -f "$self" ]] || die "$(t err_root)"
  command -v sudo >/dev/null 2>&1 || die "$(t err_root)"
  export RW_ELEVATED=1
  if [[ -t 2 ]]; then
    printf '%s\n' "$(t elevate_hint)" >&2
  fi
  if sudo -n true >/dev/null 2>&1; then
    exec sudo -n -E -- bash "$self" "$@"
  fi
  exec sudo -E -- bash "$self" "$@"
}

require_root(){ [[ ${EUID:-$(id -u)} -eq 0 ]] || die "$(t err_root)"; }
rand(){ local n="${1:-32}"; openssl rand -hex "$(( (n + 1) / 2 ))" | cut -c1-"$n"; }

# Upsert KEY=VALUE in a dotenv-like file without wiping unrelated keys.
upsert_kv(){
  local file="$1" key="$2" value="$3" tmp
  mkdir -p "$(dirname "$file")"
  touch "$file"
  chmod 600 "$file"
  tmp="$(mktemp)"
  awk -v k="$key" -v v="$value" '
    BEGIN { found=0 }
    index($0, k "=") == 1 { print k "=" v; found=1; next }
    { print }
    END { if (!found) print k "=" v }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  chmod 600 "$file"
}

persist_manager(){ upsert_kv "$ENV_FILE" "$1" "$2"; }

# Panel/single → /opt/remnawave/manager.env; edge node → /opt/remnawave-edge/manager.env.
persist_protocol_flags(){
  if [[ "${MODE:-single}" != edge || -f "$ENV_FILE" || -f "$BASE/docker-compose.yml" ]]; then
    persist_manager HYSTERIA2 "${HYSTERIA2:-0}" 2>/dev/null || true
    persist_manager ENABLE_GRPC "${ENABLE_GRPC:-0}" 2>/dev/null || true
    persist_manager ENABLE_XHTTP "${ENABLE_XHTTP:-0}" 2>/dev/null || true
  fi
  if [[ "${MODE:-}" == edge || -f "$EDGE_ENV" || -f "$EDGE_BASE/node/docker-compose.yml" ]]; then
    mkdir -p "$EDGE_BASE"
    upsert_kv "$EDGE_ENV" HYSTERIA2 "${HYSTERIA2:-0}"
    upsert_kv "$EDGE_ENV" ENABLE_GRPC "${ENABLE_GRPC:-0}"
    upsert_kv "$EDGE_ENV" ENABLE_XHTTP "${ENABLE_XHTTP:-0}"
    upsert_kv "$EDGE_ENV" MODE "${MODE:-edge}"
    [[ -n "${DOMAIN_REALITY:-}" ]] && upsert_kv "$EDGE_ENV" DOMAIN_REALITY "$DOMAIN_REALITY"
  fi
}

read_kv(){
  local file="$1" key="$2" val
  [[ -r "$file" ]] || return 1
  val="$(awk -F= -v k="$key" 'index($0, k "=")==1 { print substr($0, length(k)+2) }' "$file" | tail -1)"
  val="${val%$'\r'}"
  val="${val#\"}"; val="${val%\"}"
  val="${val#\'}"; val="${val%\'}"
  [[ -n "$val" ]] || return 1
  printf '%s' "$val"
}

host_from_text(){
  local u="$1"
  u="$(printf '%s' "$u" | tr -d '\r')"
  u="${u##* }"
  u="${u#https://}"
  u="${u#http://}"
  u="${u%%/*}"
  u="${u%%:*}"
  printf '%s' "$u"
}

fill_empty(){
  local var="$1" val="${2:-}"
  [[ -n "${!var:-}" ]] && return 0
  [[ -n "$val" ]] || return 1
  printf -v "$var" '%s' "$val"
  export "$var"
}

detect_install_mode(){
  [[ -n "${MODE:-}" ]] && return 0
  if [[ -f "$EDGE_BASE/node/docker-compose.yml" && ! -f "$BASE/docker-compose.yml" ]]; then
    MODE=edge
  elif [[ -f "$BASE/docker-compose.yml" && ( -f "$BASE/node/docker-compose.yml" || -f /etc/nginx/conf.d/reality-site.conf ) ]]; then
    MODE=single
  elif [[ -f "$BASE/docker-compose.yml" ]]; then
    MODE=panel
  else
    MODE=single
  fi
  export MODE
}

already_installed(){
  [[ -f "$BASE/docker-compose.yml" ]] || [[ -f "$EDGE_BASE/node/docker-compose.yml" ]] \
    || docker inspect remnawave >/dev/null 2>&1 || docker inspect remnanode >/dev/null 2>&1
}

hydrate_install_state(){
  local names n recovered=0
  load_kv_file "$ENV_FILE"
  load_kv_file "$BOOTSTRAP_FILE"
  load_kv_file "$EDGE_ENV"

  fill_empty DOMAIN_PANEL "$(read_kv "$BASE/.env" PANEL_DOMAIN || true)" || true
  fill_empty DOMAIN_PANEL "$(read_kv "$BASE/.env" FRONT_END_DOMAIN || true)" || true
  fill_empty DOMAIN_SUB "$(read_kv "$BASE/.env" SUB_PUBLIC_DOMAIN || true)" || true

  if [[ -r "$CREDS_FILE" ]]; then
    fill_empty DOMAIN_PANEL "$(host_from_text "$(awk -F': ' '/^Panel:/{print $2; exit}' "$CREDS_FILE")")" || true
    fill_empty DOMAIN_SUB "$(host_from_text "$(awk -F': ' '/^Subscription:/{print $2; exit}' "$CREDS_FILE")")" || true
    fill_empty DOMAIN_REALITY "$(host_from_text "$(awk -F': ' '/^Reality SNI:/{print $2; exit}' "$CREDS_FILE")")" || true
    fill_empty ADMIN_USERNAME "$(awk -F': ' '/^Admin username:/{print $2; exit}' "$CREDS_FILE")" || true
    fill_empty API_TOKEN "$(awk -F': ' '/^API token:/{print $2; exit}' "$CREDS_FILE")" || true
    fill_empty SUB_API_TOKEN "$(awk -F': ' '/^Subscription API token:/{print $2; exit}' "$CREDS_FILE")" || true
    fill_empty NODE_SECRET_KEY "$(awk -F': ' '/^Node secret:/{print $2; exit}' "$CREDS_FILE")" || true
  fi

  if [[ -f /etc/nginx/conf.d/remnawave-web.conf ]]; then
    mapfile -t names < <(awk '/server_name/{gsub(/;/,""); print $2}' /etc/nginx/conf.d/remnawave-web.conf)
    fill_empty DOMAIN_PANEL "${names[0]:-}" || true
    fill_empty DOMAIN_SUB "${names[1]:-}" || true
  fi
  if [[ -f "$STREAM_CONF" ]]; then
    fill_empty DOMAIN_REALITY "$(awk '$2 ~ /127\.0\.0\.1:8444/{print $1; exit}' "$STREAM_CONF")" || true
    fill_empty DOMAIN_PANEL "$(awk '$2 ~ /127\.0\.0\.1:9443/{print $1; exit}' "$STREAM_CONF")" || true
  fi
  if [[ -f /etc/nginx/conf.d/reality-site.conf ]]; then
    fill_empty DOMAIN_REALITY "$(awk '/server_name/{gsub(/;/,""); print $2; exit}' /etc/nginx/conf.d/reality-site.conf)" || true
  fi

  if [[ -n "${DOMAIN_PANEL:-}${DOMAIN_SUB:-}${DOMAIN_REALITY:-}" && -d /etc/letsencrypt/live ]]; then
    while IFS= read -r n; do
      [[ -n "$n" && "$n" != README ]] || continue
      if [[ "$n" == "${DOMAIN_PANEL:-}" || "$n" == "${DOMAIN_SUB:-}" || "$n" == "${DOMAIN_REALITY:-}" ]]; then
        continue
      fi
      if [[ -z "${DOMAIN_PANEL:-}" ]]; then fill_empty DOMAIN_PANEL "$n" || true; continue; fi
      if [[ -z "${DOMAIN_SUB:-}" ]]; then fill_empty DOMAIN_SUB "$n" || true; continue; fi
      if [[ -z "${DOMAIN_REALITY:-}" ]]; then fill_empty DOMAIN_REALITY "$n" || true; continue; fi
    done < <(ls /etc/letsencrypt/live 2>/dev/null | grep -v README || true)
  fi

  detect_install_mode

  if [[ $EUID -eq 0 && -n "${DOMAIN_PANEL:-}${DOMAIN_SUB:-}${DOMAIN_REALITY:-}" ]]; then
    [[ -n "${DOMAIN_PANEL:-}" ]] && persist_manager DOMAIN_PANEL "$DOMAIN_PANEL"
    [[ -n "${DOMAIN_SUB:-}" ]] && persist_manager DOMAIN_SUB "$DOMAIN_SUB"
    [[ -n "${DOMAIN_REALITY:-}" ]] && persist_manager DOMAIN_REALITY "$DOMAIN_REALITY"
    persist_manager MODE "${MODE:-single}"
    if [[ ${HYDRATE_QUIET:-0} -eq 0 ]]; then
      ok "$(t recover_domains "${DOMAIN_PANEL:--}" "${DOMAIN_SUB:--}" "${DOMAIN_REALITY:--}")"
    fi
  fi
}

ensure_repair_domains(){
  hydrate_install_state
  detect_install_mode
  if ! already_installed && [[ -z "${DOMAIN_PANEL:-}" && -z "${DOMAIN_REALITY:-}" ]]; then
    die "$(t err_repair_no_install)"
  fi
  case "${MODE:-single}" in
    edge)
      ask DOMAIN_REALITY "$(t ask_reality)" "${DOMAIN_REALITY:-}" validate_domain
      ;;
    panel)
      ask DOMAIN_PANEL "$(t ask_panel)" "${DOMAIN_PANEL:-}" validate_domain
      ask DOMAIN_SUB "$(t ask_sub)" "${DOMAIN_SUB:-}" validate_domain
      ;;
    *)
      ask DOMAIN_PANEL "$(t ask_panel)" "${DOMAIN_PANEL:-}" validate_domain
      ask DOMAIN_SUB "$(t ask_sub)" "${DOMAIN_SUB:-}" validate_domain
      ask DOMAIN_REALITY "$(t ask_reality)" "${DOMAIN_REALITY:-}" validate_domain
      ;;
  esac
  persist_manager DOMAIN_PANEL "${DOMAIN_PANEL:-}"
  persist_manager DOMAIN_SUB "${DOMAIN_SUB:-}"
  persist_manager DOMAIN_REALITY "${DOMAIN_REALITY:-}"
  persist_manager MODE "${MODE:-single}"
}

set_ui_lang(){
  local n
  n="$(normalize_lang "${1:-}")" || n=ru
  RW_LANG="$n"
  RW_LANG_SAVED=1
  if [[ $EUID -eq 0 ]] && { [[ -f "$ENV_FILE" ]] || already_installed; }; then
    persist_manager RW_LANG "$RW_LANG" 2>/dev/null || true
  fi
  ok "$(t lang_set)"
}

choose_language(){
  local choice def=2
  init_ui_colors
  [[ "${RW_LANG:-ru}" == en ]] && def=1
  echo
  echo "${U_BLUE}${U_BOLD}$(t lang_title)${U_RESET}"
  echo "  ${U_BLUE}1)${U_RESET} $(t lang_en)"
  echo "  ${U_BLUE}2)${U_RESET} $(t lang_ru)"
  if [[ $AUTO_YES -eq 1 ]]; then
    choice="$def"
  else
    read -r -p "[$def]: " choice
    choice="${choice:-$def}"
  fi
  case "$choice" in
    1|en|EN|english|English) set_ui_lang en ;;
    *) set_ui_lang ru ;;
  esac
}

validate_password(){
  [[ ${#1} -ge 24 && "$1" =~ [[:upper:]] && "$1" =~ [[:lower:]] && "$1" =~ [[:digit:]] ]]
}

nginx_supports_ssl_reject(){
  local ver major minor
  ver="$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  major="${ver%%.*}"
  minor="${ver#*.}"
  [[ -n "$major" && -n "$minor" ]] || return 1
  (( major > 1 || (major == 1 && minor >= 19) ))
}

write_reject_vhost(){
  local listen="${1:-127.0.0.1:9444}"
  mkdir -p /etc/nginx/ssl
  if [[ ! -f /etc/nginx/ssl/dummy.crt || ! -f /etc/nginx/ssl/dummy.key ]]; then
    openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 3650       -keyout /etc/nginx/ssl/dummy.key -out /etc/nginx/ssl/dummy.crt       -subj '/CN=localhost' >/dev/null 2>&1
    chmod 600 /etc/nginx/ssl/dummy.key
  fi
  if nginx_supports_ssl_reject; then
    cat > /etc/nginx/conf.d/reality-reject.conf <<EOF2
server { listen ${listen} ssl; ssl_reject_handshake on; }
EOF2
  else
    cat > /etc/nginx/conf.d/reality-reject.conf <<EOF2
server {
  listen ${listen} ssl;
  ssl_certificate /etc/nginx/ssl/dummy.crt;
  ssl_certificate_key /etc/nginx/ssl/dummy.key;
  return 444;
}
EOF2
  fi
}

# Address the panel container can use to reach a host-network remnanode.
# 127.0.0.1 inside the remnawave container is NOT the host.
node_host_address(){
  local gw
  gw="$(docker network inspect remnawave-network --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null | awk 'NF{print; exit}')"
  if validate_ip "${gw:-}"; then
    printf '%s' "$gw"
    return 0
  fi
  gw="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)"
  if validate_ip "${gw:-}" && [[ "$gw" != 127.0.0.1 ]]; then
    printf '%s' "$gw"
    return 0
  fi
  die 'Не удалось определить адрес хоста для Node. 127.0.0.1 из контейнера панели недоступен.'
}

docker_node_subnet(){
  docker network inspect remnawave-network --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null | awk 'NF{print; exit}'
}

validate_domain(){ [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]]; }
validate_email(){ [[ "$1" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; }
validate_ip(){ [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && awk -F. '{for(i=1;i<=4;i++) if($i>255) exit 1}' <<<"$1"; }
public_ip(){ curl -4fsS --max-time 8 https://api.ipify.org || true; }
ssh_ports(){
  local ports p line
  ports=''

  # Preferred source: effective sshd configuration.
  while read -r p; do
    if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 )); then
      ports+="$p"$'\n'
    fi
  done < <(sshd -T 2>/dev/null | awk '$1=="port"{print $2}' || true)

  # Fallback for socket-activated OpenSSH / configs where sshd -T is empty.
  if [[ -z "$ports" ]]; then
    while read -r p; do
      if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 )); then
        ports+="$p"$'\n'
      fi
    done < <(
      grep -hE '^[[:space:]]*Port[[:space:]]+[0-9]+' \
        /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
        | awk '{print $2}'
    )
  fi

  # Fallback for systemd socket activation.
  if [[ -z "$ports" ]] && command -v systemctl >/dev/null 2>&1; then
    while read -r line; do
      p="$(sed -nE 's/.*:([0-9]+)$/\1/p' <<<"$line")"
      if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 )); then
        ports+="$p"$'\n'
      fi
    done < <(
      systemctl show ssh.socket -p Listen -p ListenStream --value 2>/dev/null \
        | tr ' ' '\n' || true
    )
  fi

  # Final safe fallback: Ubuntu/OpenSSH default.
  if [[ -z "$ports" ]]; then
    ports='22'
  fi

  printf '%s\n' "$ports" | awk 'NF{print}' | sort -nu || true
}

ssh_port(){
  local all p
  all="$(ssh_ports || true)"
  p="${all%%$'\n'*}"
  printf '%s\n' "${p:-22}"
}

ssh_port_list(){
  local all
  all="$(ssh_ports || true)"
  all="${all//$'\n'/,}"
  all="${all%,}"
  printf '%s\n' "${all:-22}"
}

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
      [[ -n "$default" ]] || die "$(t err_yes_var "$var")"
      val="$default"
    elif [[ -n "$default" ]]; then
      read -r -p "${C_CYAN}?${C_RESET} $prompt [$default]: " val; val="${val:-$default}"
    else
      while :; do read -r -p "${C_CYAN}?${C_RESET} $prompt: " val; [[ -n "$val" ]] && break; done
    fi
  fi
  if [[ -n "$validator" ]]; then
    "$validator" "$val" || die "$(t err_invalid "$var" "$val")"
  fi
  printf -v "$var" '%s' "$val"
}

check_os(){
  [[ -r /etc/os-release ]] || die "$(t err_os_release)"
  # Поддерживаем Debian/Ubuntu; на иных системах намеренно останавливаемся.
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in ubuntu|debian) ;; *) die "$(t err_os "${ID:-unknown}")";; esac
}

install_base(){
  export DEBIAN_FRONTEND=noninteractive
  check_os
  log "$(t pkg_installing)"
  if [[ $DRY_RUN -eq 1 ]]; then
    log '[DRY-RUN] apt-get update + full-upgrade + autoremove/autoclean, затем установка Docker/nginx/certbot/UFW/fail2ban/rclone/age'
    return 0
  fi
  apt-get update -qq
  if already_installed && [[ ${FORCE_OS_UPGRADE:-0} -eq 0 ]]; then
    log "$(t skip_upgrade)"
  else
    log "$(t os_upgrading)"
    dpkg --configure -a
    apt-get -f install -y -qq
    apt-get full-upgrade -y -qq
    apt-get autoremove --purge -y -qq
    apt-get autoclean -qq
    if [[ -f /var/run/reboot-required ]]; then
      warn "$(t os_reboot)"
    else
      ok "$(t os_done)"
    fi
  fi
  apt-get install -y -qq ca-certificates curl wget jq openssl nginx certbot ufw unzip socat python3 \
    libnginx-mod-stream fail2ban unattended-upgrades rclone age file logrotate
  if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; fi
  systemctl enable --now docker nginx fail2ban >/dev/null 2>&1 || true
  docker compose version >/dev/null 2>&1 || die "$(t err_compose)"
  nginx -V 2>&1 | grep -q 'stream' || warn 'Проверка stream-модуля через nginx -V не дала результата; проверим nginx -t после загрузки модуля.'
  ok "$(t pkg_ok)"
}

configure_security(){
  local p ssh_list
  ssh_list="$(ssh_port_list)"
  p="$(ssh_port)"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[DRY-RUN] fail2ban SSH порты $ssh_list, unattended-upgrades, Docker log rotation, UFW"
    return 0
  fi
  cat > /etc/fail2ban/jail.local <<EOF2
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = $ssh_list
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
  local mode="$1" p ssh_list
  ssh_list="$(ssh_port_list)"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[DRY-RUN] UFW: SSH $ssh_list/tcp, 80/tcp, 443/tcp; Single: Node 2222 только с Docker-сети; Edge: 2222 только с Panel IP; UDP/443 и UDP/8443 если Hysteria2; TCP/8443 gRPC; TCP/4443 xHTTP"
    return 0
  fi
  ufw default deny incoming >/dev/null || true
  ufw default allow outgoing >/dev/null || true
  while read -r p; do
    [[ -n "$p" ]] && ufw allow "$p/tcp" >/dev/null || true
  done < <(ssh_ports || true)
  ufw allow 80/tcp >/dev/null || true
  ufw allow 443/tcp >/dev/null || true
  if [[ "$mode" == edge || "$mode" == single ]]; then
    [[ $HYSTERIA2 -eq 1 ]] && ufw allow 443/udp >/dev/null || true
    [[ $HYSTERIA2 -eq 1 ]] && ufw allow 8443/udp >/dev/null || true
    [[ $ENABLE_GRPC -eq 1 ]] && ufw allow 8443/tcp >/dev/null || true
    [[ $ENABLE_XHTTP -eq 1 ]] && ufw allow 4443/tcp >/dev/null || true
  fi
  if [[ "$mode" == edge ]]; then
    validate_ip "${PANEL_IP:-}" || die "$(t err_panel_ip)"
    ufw allow from "$PANEL_IP" to any port 2222 proto tcp >/dev/null || true
  fi
  if [[ "$mode" == single ]]; then
    local subnet
    subnet="$(docker_node_subnet || true)"
    if [[ -n "${subnet:-}" ]]; then
      ufw allow from "$subnet" to any port 2222 proto tcp >/dev/null || true
    else
      ufw allow from 172.16.0.0/12 to any port 2222 proto tcp >/dev/null || true
    fi
  fi
  # Docker-сеть не должна случайно открывать host-порты наружу.
  ufw --force enable >/dev/null || true
  ok "$(t fw_ok)"
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
    upsert_kv .env "$key" "$value"
  }
  set_env APP_PORT 3000
  set_env METRICS_PORT 3001
  set_env API_INSTANCES 1
  set_env APP_SECRET "$appsecret"
  set_env REDIS_SOCKET /var/run/valkey/valkey.sock
  set_env DATABASE_URL "\"postgresql://postgres:${pgpass}@remnawave-db:5432/postgres\""
  set_env PANEL_DOMAIN "$DOMAIN_PANEL"
  set_env FRONT_END_DOMAIN "${DOMAIN_PANEL}"
  set_env SUB_PUBLIC_DOMAIN "${DOMAIN_SUB}"
  set_env METRICS_USER admin
  set_env METRICS_PASS "$metrics_pass"
  set_env WEBHOOK_SECRET_HEADER "$webhooksecret"
  set_env IS_TELEGRAM_NOTIFICATIONS_ENABLED false
  set_env WEBHOOK_ENABLED false
  set_env POSTGRES_USER postgres
  set_env POSTGRES_PASSWORD "$pgpass"
  set_env POSTGRES_DB postgres
  chmod 600 .env
  persist_manager MODE "${MODE:-single}"
  persist_manager DOMAIN_PANEL "${DOMAIN_PANEL:-}"
  persist_manager DOMAIN_SUB "${DOMAIN_SUB:-}"
  persist_manager DOMAIN_REALITY "${DOMAIN_REALITY:-}"
  persist_manager DOMAIN_NODE "${DOMAIN_NODE:-}"
  persist_manager EDGE_ADDRESS "${EDGE_ADDRESS:-}"
  persist_manager ADMIN_EMAIL "${ADMIN_EMAIL:-}"
  persist_manager ADMIN_USERNAME "${ADMIN_USERNAME:-}"
  persist_manager ADMIN_PASSWORD "${ADMIN_PASSWORD:-}"
  persist_manager POSTGRES_PASSWORD "$pgpass"
  persist_manager METRICS_PASS "$metrics_pass"
  persist_manager API_TOKEN "${API_TOKEN:-}"
  persist_manager SUB_API_TOKEN "${SUB_API_TOKEN:-}"
  persist_manager NODE_SECRET_KEY "${NODE_SECRET_KEY:-}"
  persist_manager RW_LANG "${RW_LANG:-ru}"
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
  local proxy_host="${DOMAIN_PANEL:-localhost}"
  local args=(-sS --max-time 30 -X "$method"
    -H 'Content-Type: application/json'
    -H 'Accept: application/json'
    -H 'X-Forwarded-For: 127.0.0.1'
    -H 'X-Forwarded-Proto: https'
    -H "X-Forwarded-Host: ${proxy_host}"
    -H "Host: ${proxy_host}"
    -H 'X-Remnawave-Client-Type: browser')
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
api_json_soft(){
  local raw code json; raw="${1:-}"; code="$(tail -n1 <<<"$raw")"; json="$(sed '$d' <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || return 1
  jq -e . >/dev/null <<<"$json" 2>/dev/null || return 1
  printf '%s' "$json"
}
wait_api(){
  local proxy_host="${DOMAIN_PANEL:-localhost}"
  for _ in {1..90}; do
    if curl -fsS --max-time 2 \
      -H 'X-Forwarded-For: 127.0.0.1' \
      -H 'X-Forwarded-Proto: https' \
      -H "X-Forwarded-Host: ${proxy_host}" \
      -H "Host: ${proxy_host}" \
      "$API_LOCAL/auth/status" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  die 'Remnawave API не отвечает через внутренний proxy-check path.'
}

create_named_token(){
  local name="$1" scopes_json="$2" raw code json token
  raw="$(api_call POST /tokens/ "$(jq -nc --arg n "$name" --argjson s "$scopes_json" '{name:$n,expiresInDays:3650,scopes:$s}')" "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  json="$(sed '$d' <<<"$raw")"
  if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
    token="$(jq -r '.response.token // empty' <<<"$json")"
    [[ -n "$token" && "$token" != null ]] && { printf '%s' "$token"; return 0; }
  fi
  name="${name:0:20}-$(date +%s | tail -c 8)"
  name="${name:0:30}"
  raw="$(api_call POST /tokens/ "$(jq -nc --arg n "$name" --argjson s "$scopes_json" '{name:$n,expiresInDays:3650,scopes:$s}')" "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  json="$(sed '$d' <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || return 1
  token="$(jq -r '.response.token // empty' <<<"$json")"
  [[ -n "$token" && "$token" != null ]] || return 1
  printf '%s' "$token"
}

bootstrap_auth(){
  if [[ -n "${API_TOKEN:-}" ]]; then
    if api_json "$(api_call GET /config-profiles/ '' "$API_TOKEN")" >/dev/null 2>&1; then
      API_JWT="${API_JWT:-$API_TOKEN}"
      ok 'Используем сохранённый API token.'
      return 0
    fi
  fi
  validate_password "${ADMIN_PASSWORD:-}" || die "$(t err_admin_pw)"
  local status reg
  status="$(api_json "$(api_call GET /auth/status)")"
  reg="$(jq -r '.response.isRegisterAllowed // false' <<<"$status")"
  if [[ "$reg" == true ]]; then
    log 'Регистрируем первого администратора.'
    API_JWT="$(api_json "$(api_call POST /auth/register "$(jq -nc --arg u "$ADMIN_USERNAME" --arg p "$ADMIN_PASSWORD" '{username:$u,password:$p}')")" | jq -r '.response.accessToken')"
  else
    log 'Регистрация уже закрыта; выполняем login существующего администратора.'
    API_JWT="$(api_json "$(api_call POST /auth/login "$(jq -nc --arg u "$ADMIN_USERNAME" --arg p "$ADMIN_PASSWORD" '{username:$u,password:$p}')")" | jq -r '.response.accessToken')" || die 'Не удалось выполнить login администратора. Проверьте ADMIN_PASSWORD; пароль сохраняется в manager.env до bootstrap.'
  fi
  [[ -n "$API_JWT" && "$API_JWT" != null ]] || die 'JWT администратора не получен.'
  API_TOKEN="$(create_named_token remna-mgr-bootstrap '["*"]')"
  [[ -n "$API_TOKEN" && "$API_TOKEN" != null ]] || die 'API Token не получен.'
  persist_manager API_TOKEN "$API_TOKEN"
}

get_node_secret(){
  if [[ -n "${NODE_SECRET_KEY:-}" ]]; then
    persist_manager NODE_SECRET_KEY "$NODE_SECRET_KEY"
    ok 'Используем переданный SECRET_KEY Node.'
    return 0
  fi
  local j secret
  j="$(api_json "$(api_call GET /keygen/ '' "$API_JWT")")"
  secret="$(jq -r '.response.secretKey // empty' <<<"$j")"
  [[ -n "$secret" ]] || die 'GET /api/keygen не вернул Node SECRET_KEY.'
  NODE_SECRET_KEY="$secret"
  persist_manager NODE_SECRET_KEY "$NODE_SECRET_KEY"
  ok 'Node SECRET_KEY получен через официальный API /api/keygen.'
}

sub_token_can_read_metadata(){
  local token="${1:-}" raw code
  [[ -n "$token" && "$token" != null ]] || return 1
  raw="$(api_call GET /system/metadata '' "$token" || true)"
  code="$(tail -n1 <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]]
}

create_subscription_token(){
  if sub_token_can_read_metadata "${SUB_API_TOKEN:-}"; then
    persist_manager SUB_API_TOKEN "$SUB_API_TOKEN"
    ok 'Subscription API token действителен (/system/metadata).'
    return 0
  fi
  [[ -z "${SUB_API_TOKEN:-}" ]] || warn 'Сохранённый SUB_API_TOKEN не читает /system/metadata; subscription-page из‑за этого падает при старте.'
  SUB_API_TOKEN="$(create_named_token remna-subpage '["subscription-page-configs:list","subscription-page-configs:get","subscriptions:subpage-config","system:metadata","users:by-username"]' || true)"
  if ! sub_token_can_read_metadata "${SUB_API_TOKEN:-}"; then
    warn 'Минимальные scopes для Subscription Page недостаточны; создаём token со scopes=["*"].'
    SUB_API_TOKEN="$(create_named_token remna-subpage '["*"]')"
  fi
  sub_token_can_read_metadata "${SUB_API_TOKEN:-}" || die 'API token для Subscription Page не проходит /system/metadata.'
  persist_manager SUB_API_TOKEN "$SUB_API_TOKEN"
  ok 'Создан API token для Subscription Page.'
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

build_xray_config(){
  local target='127.0.0.1:9450'
  [[ -n "${REALITY_SHORT_ID:-}" ]] || REALITY_SHORT_ID="$(rand 16)"
  jq -n \
    --arg target "$target" \
    --arg sni "${DOMAIN_REALITY}" \
    --arg pk "${REALITY_PRIVATE_KEY}" \
    --arg sid "${REALITY_SHORT_ID}" \
    --argjson hy2 "$([[ ${HYSTERIA2:-0} -eq 1 ]] && echo true || echo false)" \
    --argjson grpc "$([[ ${ENABLE_GRPC:-0} -eq 1 ]] && echo true || echo false)" \
    --argjson xhttp "$([[ ${ENABLE_XHTTP:-0} -eq 1 ]] && echo true || echo false)" \
    --arg cert /dev/shm/hysteria_cert.pem \
    --arg key /dev/shm/hysteria_key.pem \
    '
    def reality: {show:false, target:$target, xver:0, serverNames:[$sni], privateKey:$pk, minClientVer:"0.0.0", shortIds:[$sid]};
    def sniff: {enabled:true, destOverride:["http","tls","quic"], routeOnly:false};
    def vless: {clients:[], decryption:"none"};
    {
      log: {loglevel:"warning"},
      inbounds: [{
        tag:"VLESS_REALITY", port:8444, listen:"0.0.0.0", protocol:"vless",
        settings: vless, sniffing: sniff,
        streamSettings: {network:"raw", security:"reality", realitySettings: reality}
      }],
      outbounds: [{protocol:"freedom", tag:"DIRECT"}, {protocol:"blackhole", tag:"BLOCK"}],
      routing: {domainStrategy:"IPIfNonMatch", rules:[
        {ip:["geoip:private"], outboundTag:"BLOCK"},
        {domain:["geosite:private"], outboundTag:"BLOCK"},
        {protocol:["bittorrent"], outboundTag:"BLOCK"}
      ]}
    }
    | if $grpc then .inbounds += [{
        tag:"VLESS_GRPC_REALITY", port:8443, listen:"0.0.0.0", protocol:"vless",
        settings: vless, sniffing: sniff,
        streamSettings: {network:"grpc", security:"reality", realitySettings: reality, grpcSettings:{serviceName:"grpc", multiMode:true}}
      }] else . end
    | if $xhttp then .inbounds += [{
        tag:"VLESS_XHTTP_REALITY", port:4443, listen:"0.0.0.0", protocol:"vless",
        settings: vless, sniffing: sniff,
        streamSettings: {network:"xhttp", security:"reality", realitySettings: reality, xhttpSettings:{path:"/xhttp", host:"", mode:"auto"}}
      }] else . end
    | if $hy2 then .inbounds += [{
        tag:"HYSTERIA2", port:443, listen:"0.0.0.0", protocol:"hysteria",
        settings: {version:2, auth:""},
        streamSettings: {network:"hysteria", security:"tls", tlsSettings:{alpn:["h3"], certificates:[{certificateFile:$cert, keyFile:$key}]}}
      }] else . end
    '
}

enable_all_protocols(){
  HYSTERIA2=1
  ENABLE_GRPC=1
  ENABLE_XHTTP=1
}

set_transport(){
  local name="${1:-}" value="${2:-1}"
  name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  case "$name" in
    hysteria2|hy2|hysteria) HYSTERIA2="$value" ;;
    grpc) ENABLE_GRPC="$value" ;;
    xhttp|x-http) ENABLE_XHTTP="$value" ;;
    all)
      HYSTERIA2="$value"
      ENABLE_GRPC="$value"
      ENABLE_XHTTP="$value"
      ;;
    *) die "$(t err_nt_proto "${name:-?}")" ;;
  esac
  PROTOCOLS_EXPLICIT=1
  persist_protocol_flags
}

# hydrate_install_state sources manager.env and would undo menu 25 add/remove.
snapshot_protocol_flags(){
  _RW_SAVE_HYSTERIA2="${HYSTERIA2:-0}"
  _RW_SAVE_GRPC="${ENABLE_GRPC:-0}"
  _RW_SAVE_XHTTP="${ENABLE_XHTTP:-0}"
  _RW_SAVE_PROTOCOLS_EXPLICIT="${PROTOCOLS_EXPLICIT:-0}"
}

restore_protocol_flags(){
  [[ ${_RW_SAVE_PROTOCOLS_EXPLICIT:-0} -eq 1 ]] || return 0
  HYSTERIA2="${_RW_SAVE_HYSTERIA2:-0}"
  ENABLE_GRPC="${_RW_SAVE_GRPC:-0}"
  ENABLE_XHTTP="${_RW_SAVE_XHTTP:-0}"
  PROTOCOLS_EXPLICIT=1
  export HYSTERIA2 ENABLE_GRPC ENABLE_XHTTP PROTOCOLS_EXPLICIT
}

protocol_summary(){
  printf 'Reality'
  [[ ${HYSTERIA2:-0} -eq 1 ]] && printf ' + Hysteria2'
  [[ ${ENABLE_GRPC:-0} -eq 1 ]] && printf ' + gRPC'
  [[ ${ENABLE_XHTTP:-0} -eq 1 ]] && printf ' + xHTTP'
}

profile_inbound_uuids(){
  local existing p="${1:-$PROFILE_UUID}"
  existing="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  jq -c --arg p "$p" '[.response.configProfiles[]? | select(.uuid==$p) | .inbounds[]?.uuid | select(. != null)]' <<<"$existing"
}

profile_inbound_uuid_by_tag(){
  local tag="$1" existing p="${2:-$PROFILE_UUID}"
  existing="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  jq -r --arg p "$p" --arg t "$tag" '
    [.response.configProfiles[]? | select(.uuid==$p) | .inbounds[]? | select(.tag==$t) | .uuid] | .[0] // empty
  ' <<<"$existing"
}

list_node_uuids(){
  local existing
  if [[ -n "${TARGET_NODE_UUID:-}" ]]; then
    jq -nc --arg u "$TARGET_NODE_UUID" '[$u]'
    return 0
  fi
  existing="$(api_json "$(api_call GET /nodes/ '' "$API_JWT")")"
  jq -c '
    def nodes:
      if (.response|type)=="array" then .response[]?
      elif ((.response.nodes // empty)|type)=="array" then .response.nodes[]?
      else empty end;
    [nodes | .uuid | select(. != null and . != "")]
  ' <<<"$existing"
}

api_try_delete(){
  local collection="$1" uuid="$2" raw code
  raw="$(api_call DELETE "${collection}${uuid}" '' "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]] && return 0
  raw="$(api_call DELETE "$collection" "$(jq -nc --arg u "$uuid" '{uuid:$u}')" "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]]
}

profile_name_for_node(){
  local n="${1:-}"
  n="${n#AUTO-}"
  n="${n#"${BRAND}-"}"
  case "$n" in
    ''|"$BRAND"|SINGLE) printf '%s' "$BRAND" ;;
    EDGE) printf '%s-EDGE' "$BRAND" ;;
    *) printf '%s-%s' "$BRAND" "$n" ;;
  esac
}

canonical_node_name(){
  local n="${1:-}"
  case "$n" in
    AUTO|AUTO-SINGLE|"${BRAND}-SINGLE") printf '%s' "$BRAND" ;;
    AUTO-EDGE) printf '%s-EDGE' "$BRAND" ;;
    *) printf '%s' "$n" ;;
  esac
}

# Remnawave ships Default-Profile / Default / AUTO leftover names.
# Compare folded so "Default Profile" matches without a space in `case`.
is_discard_name(){
  local kind="$1" n="${2:-}"
  n="${n,,}"
  n="${n// /}"
  n="${n//_/}"
  n="${n//-/}"
  if [[ "$kind" == squad ]]; then
    case "$n" in
      defaultprofile|default|defaultsquad|auto) return 0 ;;
    esac
  else
    case "$n" in
      defaultprofile|default|autoprofile|auto) return 0 ;;
    esac
  fi
  return 1
}

brand_inbound_uuids(){
  local existing prefix="$BRAND"
  existing="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  jq -c --arg p "$prefix" '
    [.response.configProfiles[]?
      | select(.name==$p or ((.name // "") | startswith($p+"-")))
      | .inbounds[]?.uuid | select(. != null)]
  ' <<<"$existing"
}

create_config_profile(){
  local name="${1:-$BRAND}" existing profile created body
  [[ -n "${REALITY_SHORT_ID:-}" ]] || REALITY_SHORT_ID="$(rand 16)"
  existing="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  PROFILE_UUID="$(jq -r --arg n "$name" '[.response.configProfiles[]? | select(.name==$n) | .uuid] | .[0] // empty' <<<"$existing")"
  if [[ -z "$PROFILE_UUID" && "$name" == "$BRAND" ]]; then
    PROFILE_UUID="$(jq -r '[.response.configProfiles[]? | select(.name=="AUTO-PROFILE") | .uuid] | .[0] // empty' <<<"$existing")"
  fi
  profile="$(build_xray_config)"
  if [[ -n "$PROFILE_UUID" ]]; then
    body="$(jq -nc --arg u "$PROFILE_UUID" --arg n "$name" --argjson c "$profile" '{uuid:$u,name:$n,config:$c}')"
    api_json "$(api_call PATCH /config-profiles/ "$body" "$API_JWT")" >/dev/null
    ok "Профиль $name обновлён ($(protocol_summary))."
  else
    created="$(api_json "$(api_call POST /config-profiles/ "$(jq -nc --arg n "$name" --argjson c "$profile" '{name:$n,config:$c}')" "$API_JWT")")"
    PROFILE_UUID="$(jq -r '.response.uuid // empty' <<<"$created")"
    ok "Профиль $name создан ($(protocol_summary))."
  fi
  [[ -n "$PROFILE_UUID" && "$PROFILE_UUID" != null ]] || die "Config Profile $name: UUID не получен."
  existing="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  INBOUND_UUID="$(jq -r --arg p "$PROFILE_UUID" '
    [.response.configProfiles[]? | select(.uuid==$p) | .inbounds[]? | select(.tag=="VLESS_REALITY") | .uuid] | .[0]
    // ([.response.configProfiles[]? | select(.uuid==$p) | .inbounds[0].uuid] | .[0])
    // empty
  ' <<<"$existing")"
  [[ -n "$INBOUND_UUID" && "$INBOUND_UUID" != null ]] || die "Профиль $name: inbound VLESS_REALITY не найден."
  persist_manager PROFILE_UUID "$PROFILE_UUID"
  persist_manager INBOUND_UUID "$INBOUND_UUID"
}

node_body(){
  local name="$1" address="$2" inbound_uuids="$3" uuid="${4:-}" plugin_uuid="${5:-}"
  jq -nc \
    --arg n "$name" --arg a "$address" --arg p "$PROFILE_UUID" --argjson ibs "$inbound_uuids" \
    --arg uuid "$uuid" --arg pl "$plugin_uuid" \
    '{
      name:$n, address:$a, port:2222, countryCode:"XX",
      configProfile:{activeConfigProfileUuid:$p, activeInbounds:$ibs},
      isTrafficTrackingActive:false, trafficLimitBytes:0, notifyPercent:0,
      trafficResetDay:31, consumptionMultiplier:1.0
    }
    + (if $uuid != "" then {uuid:$uuid} else {} end)
    + (if $pl != "" then {activePluginUuid:$pl} else {} end)'
}

create_node(){
  local address="$1" name="${2:-$BRAND}" existing body node inbound_uuids plugin_uuid="" plugin_raw="" pname
  name="$(canonical_node_name "$name")"
  pname="$(profile_name_for_node "$name")"
  create_config_profile "$pname"
  existing="$(api_json "$(api_call GET /nodes/ '' "$API_JWT")")"
  if [[ "$name" == "${BRAND}-EDGE" ]]; then
    NODE_UUID="$(jq -r --arg n "$name" \
      '[.response[]? | select(.name==$n or .name=="AUTO-EDGE") | .uuid] | .[0] // empty' <<<"$existing")"
  else
    NODE_UUID="$(jq -r --arg n "$name" --arg brand "$BRAND" \
      '[.response[]? | select(.name==$n or .name=="AUTO-SINGLE" or .name=="AUTO" or .name==($brand+"-SINGLE")) | .uuid] | .[0] // empty' <<<"$existing")"
  fi
  inbound_uuids="$(profile_inbound_uuids)"
  [[ -n "$inbound_uuids" && "$inbound_uuids" != '[]' ]] || die "$(t err_node_inbound "$pname")"
  plugin_raw="$(api_call GET "/node-plugins/?_=$(date +%s)" "" "$API_JWT" 2>/dev/null || true)"
  plugin_uuid="$(sed '$d' <<<"$plugin_raw" | jq -r '[.response.nodePlugins[]?] | map(select(.name=="Reverse Node Plugins" or ((.pluginConfig // {}) | has("torrentBlocker")))) | .[0].uuid // empty' 2>/dev/null || true)"
  if [[ -n "$NODE_UUID" ]]; then
    body="$(node_body "$name" "$address" "$inbound_uuids" "$NODE_UUID" "$plugin_uuid")"
    api_json "$(api_call PATCH /nodes/ "$body" "$API_JWT")" >/dev/null || \
      die "Не удалось привязать inbound'ы к ноде $name через PATCH /nodes/ (uuid в теле)."
    persist_manager NODE_UUID "$NODE_UUID"
    ok "$(t node_updated "$name" "$pname")"
    return 0
  fi
  body="$(node_body "$name" "$address" "$inbound_uuids" "" "$plugin_uuid")"
  node="$(api_json "$(api_call POST /nodes/ "$body" "$API_JWT")")"
  NODE_UUID="$(jq -r '.response.uuid // empty' <<<"$node")"
  [[ -n "$NODE_UUID" && "$NODE_UUID" != null ]] || die "$(t err_node_create)"
  persist_manager NODE_UUID "$NODE_UUID"
  ok "$(t node_created "$name" "$pname" "$(protocol_summary)")"
}

bind_nodes_to_profile(){
  local inbound_uuids uuid name address existing pname body
  existing="$(api_json "$(api_call GET /nodes/ '' "$API_JWT")")"
  if [[ "$(jq -r '[.response[]?.uuid] | length' <<<"$existing")" -eq 0 ]]; then
    create_config_profile "$BRAND"
    ok 'Нод ещё нет — профиль CorgiLusi готов, карточка Node привяжется при появлении.'
    return 0
  fi
  while IFS=$'\t' read -r uuid name address; do
    [[ -n "$uuid" ]] || continue
    if [[ -n "${TARGET_NODE_UUID:-}" && "$uuid" != "$TARGET_NODE_UUID" ]]; then
      continue
    fi
    name="$(canonical_node_name "$name")"
    pname="$(profile_name_for_node "$name")"
    create_config_profile "$pname"
    inbound_uuids="$(profile_inbound_uuids)"
    body="$(jq -nc --arg u "$uuid" --arg n "$name" --arg a "$address" --arg p "$PROFILE_UUID" --argjson ibs "$inbound_uuids" \
      '{uuid:$u, name:$n, address:$a, configProfile:{activeConfigProfileUuid:$p, activeInbounds:$ibs}}')"
    api_json "$(api_call PATCH /nodes/ "$body" "$API_JWT")" >/dev/null || \
      die "Не удалось привязать ноду $name к профилю $pname."
    ok "Нода $name → профиль $pname."
  done < <(jq -r '.response[]? | [(.uuid // ""), (.name // "node"), (.address // "")] | @tsv' <<<"$existing")
}

restart_all_nodes(){
  local raw code uuid existing ok_n=0
  raw="$(api_call POST /nodes/actions/restart-all '{}' "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
    ok 'Ноды перезапущены, чтобы подтянуть новый профиль.'
    return 0
  fi
  raw="$(api_call POST /nodes/actions/restart-all '' "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
    ok 'Ноды перезапущены, чтобы подтянуть новый профиль.'
    return 0
  fi
  existing="$(api_json_soft "$(api_call GET /nodes/ '' "$API_JWT" 2>/dev/null || true)" || true)"
  if [[ -n "$existing" ]]; then
    while IFS= read -r uuid; do
      [[ -n "$uuid" ]] || continue
      raw="$(api_call POST /nodes/actions/restart "$(jq -nc --arg u "$uuid" '{uuid:$u}')" "$API_JWT" || true)"
      code="$(tail -n1 <<<"$raw")"
      if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
        raw="$(api_call POST /nodes/actions/restart "$(jq -nc --arg u "$uuid" '{uuids:[$u]}')" "$API_JWT" || true)"
        code="$(tail -n1 <<<"$raw")"
      fi
      [[ "$code" =~ ^2[0-9][0-9]$ ]] && ok_n=$((ok_n + 1))
    done < <(jq -r '
      def nodes:
        if (.response|type)=="array" then .response[]?
        elif ((.response.nodes // empty)|type)=="array" then .response.nodes[]?
        else empty end;
      nodes | .uuid // empty
    ' <<<"$existing")
  fi
  if [[ "$ok_n" -gt 0 ]]; then
    ok 'Ноды перезапущены, чтобы подтянуть новый профиль.'
    return 0
  fi
  warn "Перезапуск нод через API не выполнен (HTTP ${code:-000}); remnanode подхватит профиль сам."
}

ensure_internal_squad(){
  local inbound_uuids existing body created
  inbound_uuids="$(brand_inbound_uuids)"
  [[ -n "$inbound_uuids" && "$inbound_uuids" != '[]' ]] || inbound_uuids="$(profile_inbound_uuids)"
  [[ -n "$inbound_uuids" && "$inbound_uuids" != '[]' ]] || die "Нет inbound UUID для сквада $BRAND."
  existing="$(api_json "$(api_call GET /internal-squads/ '' "$API_JWT")")"
  SQUAD_UUID="$(jq -r --arg n "$BRAND" --arg old AUTO \
    '([.response.internalSquads[]? | select(.name==$n) | .uuid] | .[0])
     // ([.response.internalSquads[]? | select(.name==$old) | .uuid] | .[0])
     // empty' <<<"$existing")"
  if [[ -n "$SQUAD_UUID" ]]; then
    body="$(jq -nc --arg u "$SQUAD_UUID" --arg n "$BRAND" --argjson ibs "$inbound_uuids" '{uuid:$u,name:$n,inbounds:$ibs}')"
    api_json "$(api_call PATCH /internal-squads/ "$body" "$API_JWT")" >/dev/null || \
      die "Не удалось обновить сквад $BRAND."
  else
    created="$(api_json "$(api_call POST /internal-squads/ "$(jq -nc --arg n "$BRAND" --argjson ibs "$inbound_uuids" '{name:$n,inbounds:$ibs}')" "$API_JWT")")"
    SQUAD_UUID="$(jq -r '.response.uuid // empty' <<<"$created")"
  fi
  [[ -n "$SQUAD_UUID" && "$SQUAD_UUID" != null ]] || die "Сквад $BRAND не создан."
  persist_manager SQUAD_UUID "$SQUAD_UUID"
  ok "Сквад $BRAND содержит inbound'ы профилей CorgiLusi. Пользователей в панели назначать не нужно."
}

remove_default_profile_and_squads(){
  local existing uuid name
  existing="$(api_json "$(api_call GET /internal-squads/ '' "$API_JWT")")"
  while IFS=$'\t' read -r uuid name; do
    [[ -n "$uuid" ]] || continue
    [[ "$uuid" == "${SQUAD_UUID:-}" ]] && continue
    [[ "$name" == "$BRAND" ]] && continue
    if is_discard_name squad "$name"; then
      if api_try_delete /internal-squads/ "$uuid"; then
        ok "Внутренний сквад «$name» удалён."
      else
        warn "Не удалось удалить сквад «$name» ($uuid)."
      fi
    fi
  done < <(jq -r '.response.internalSquads[]? | [(.uuid // ""), (.name // "")] | @tsv' <<<"$existing")

  existing="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  while IFS=$'\t' read -r uuid name; do
    [[ -n "$uuid" ]] || continue
    [[ "$uuid" == "${PROFILE_UUID:-}" ]] && continue
    [[ "$name" == "$BRAND" || "$name" == "$BRAND"-* ]] && continue
    if is_discard_name profile "$name"; then
      if api_try_delete /config-profiles/ "$uuid"; then
        ok "Профиль «$name» удалён."
      else
        warn "Не удалось удалить профиль «$name» ($uuid). Сквад Default-Profile уже снят."
      fi
    fi
  done < <(jq -r '.response.configProfiles[]? | [(.uuid // ""), (.name // "")] | @tsv' <<<"$existing")
}

create_host(){
  local address="$1" remark="${2:-VLESS Reality}" port="${3:-443}" tag="${4:-VLESS_REALITY}"
  local ib existing body host path_v='' host_v='' alpn_v='' fp='' nodes_json
  ib="$(profile_inbound_uuid_by_tag "$tag")"
  [[ -n "$ib" ]] || ib="$INBOUND_UUID"
  [[ -n "$ib" ]] || die "$(t err_host_tag "$tag")"
  case "$tag" in
    VLESS_REALITY) fp='firefox' ;;
    VLESS_GRPC_REALITY) path_v='/grpc'; host_v="${DOMAIN_REALITY}"; fp='firefox' ;;
    VLESS_XHTTP_REALITY) path_v='/xhttp'; host_v="${DOMAIN_REALITY}"; fp='firefox' ;;
    HYSTERIA2) alpn_v='h3' ;;
  esac
  nodes_json="${HOST_NODES_JSON:-}"
  if [[ -z "$nodes_json" ]]; then
    nodes_json="$(list_node_uuids)"
  fi
  if [[ "$nodes_json" == '[]' && -n "${NODE_UUID:-}" ]]; then
    nodes_json="$(jq -nc --arg u "$NODE_UUID" '[$u]')"
  fi
  existing="$(api_json "$(api_call GET /hosts/ '' "$API_JWT")")"
  HOST_UUID="$(jq -r --arg a "$address" --arg r "$remark" --arg cp "$PROFILE_UUID" --arg ib "$ib" \
    '[.response[]? | select(.remark==$r and .address==$a and (.inbound.configProfileUuid==$cp) and (.inbound.configProfileInboundUuid==$ib)) | .uuid] | .[0] // empty' <<<"$existing")"
  body="$(jq -nc \
    --arg cp "$PROFILE_UUID" --arg ib "$ib" --arg a "$address" --arg s "$DOMAIN_REALITY" \
    --arg r "$remark" --argjson p "$port" --arg path "$path_v" --arg h "$host_v" \
    --arg alpn "$alpn_v" --arg fp "$fp" --argjson nodes "$nodes_json" --arg squad "${SQUAD_UUID:-}" --arg uuid "${HOST_UUID:-}" \
    '{
      inbound:{configProfileUuid:$cp, configProfileInboundUuid:$ib},
      remark:$r, address:$a, port:$p, sni:$s,
      securityLayer:"DEFAULT",
      isDisabled:false, isHidden:false, nodes:$nodes
    }
    + (if $fp != "" then {fingerprint:$fp} else {} end)
    + (if $uuid != "" then {uuid:$uuid} else {} end)
    + (if $path != "" then {path:$path} else {} end)
    + (if $h != "" then {host:$h} else {} end)
    + (if $alpn != "" then {alpn:$alpn} else {} end)
    + (if $squad != "" then {internalSquads:{mode:"ALLOW_ONLY", squads:[$squad]}} else {} end)')"
  if [[ -n "$HOST_UUID" ]]; then
    host="$(api_json "$(api_call PATCH /hosts/ "$body" "$API_JWT")")"
  else
    host="$(api_json "$(api_call POST /hosts/ "$body" "$API_JWT")")"
    HOST_UUID="$(jq -r '.response.uuid // empty' <<<"$host")"
  fi
  [[ -n "$HOST_UUID" && "$HOST_UUID" != null ]] || die "$(t err_host_create "$remark")"
  ok "Host «$remark» готов (порт $port$([[ -n "$fp" ]] && echo ", fingerprint $fp")$([[ -n "$path_v" ]] && echo ", path $path_v")$([[ -n "$alpn_v" ]] && echo ", ALPN $alpn_v"))."
}

create_protocol_hosts(){
  local address="$1"
  [[ -n "$address" ]] || die "$(t err_host_empty)"
  create_host "$address" 'VLESS Reality' 443 VLESS_REALITY
  if [[ ${ENABLE_GRPC:-0} -eq 1 ]]; then
    create_host "$address" 'VLESS gRPC Reality' 8443 VLESS_GRPC_REALITY
  fi
  if [[ ${ENABLE_XHTTP:-0} -eq 1 ]]; then
    create_host "$address" 'VLESS xHTTP Reality' 4443 VLESS_XHTTP_REALITY
  fi
  if [[ ${HYSTERIA2:-0} -eq 1 ]]; then
    create_host "$address" 'Hysteria2' 443 HYSTERIA2
  fi
}

prune_protocol_hosts(){
  local existing profiles uuid tag remark
  existing="$(api_json "$(api_call GET /hosts/ '' "$API_JWT")")"
  profiles="$(api_json "$(api_call GET /config-profiles/ '' "$API_JWT")")"
  while IFS=$'\t' read -r uuid tag remark; do
    [[ -n "$uuid" ]] || continue
    if api_try_delete /hosts/ "$uuid"; then
      ok "$(t nt_pruned "$remark" "$tag")"
    else
      warn "Host «$remark» ($uuid) не удалён."
    fi
  done < <(jq -r \
    --arg hy2 "${HYSTERIA2:-0}" \
    --arg grpc "${ENABLE_GRPC:-0}" \
    --arg xhttp "${ENABLE_XHTTP:-0}" \
    --arg target "${TARGET_NODE_UUID:-}" \
    --argjson profiles "$profiles" '
    def hosts:
      if (.response|type)=="array" then .response[]?
      elif ((.response.hosts // empty)|type)=="array" then .response.hosts[]?
      else empty end;
    def tag_of($ib):
      [($profiles.response.configProfiles // [])[]? | .inbounds[]? | select(.uuid==$ib) | .tag] | .[0] // "";
    def node_ids($h):
      [($h.nodes // [])[]? | if type=="object" then (.uuid // empty) else . end | select(. != null and . != "")];
    hosts
    | . as $h
    | ($h.uuid // "") as $u
    | ($h.remark // "") as $r
    | ($h.inbound.configProfileInboundUuid // $h.inbound.uuid // "") as $ib
    | (tag_of($ib)) as $t
    | if $u != "" and (
        (($t=="VLESS_GRPC_REALITY" or $r=="VLESS gRPC Reality") and $grpc != "1")
        or (($t=="VLESS_XHTTP_REALITY" or $r=="VLESS xHTTP Reality") and $xhttp != "1")
        or (($t=="HYSTERIA2" or $r=="Hysteria2") and $hy2 != "1")
      ) and ($target == "" or ((node_ids($h) | index($target)) != null) or (node_ids($h) | length == 0))
      then [$u, (if $t=="" then $r else $t end), $r] | @tsv
      else empty end
  ' <<<"$existing")
}

create_auto_user(){
  local existing body created expire username="$BRAND" raw code json user_uuid user_name
  [[ -n "${SQUAD_UUID:-}" ]] || return 0
  existing="$(api_call GET "/users/by-username/${username}" '' "$API_JWT" || true)"
  if [[ ! "$(tail -n1 <<<"$existing")" =~ ^2[0-9][0-9]$ ]]; then
    existing="$(api_call GET "/users/by-username/AUTO" '' "$API_JWT" || true)"
  fi
  if [[ "$(tail -n1 <<<"$existing")" =~ ^2[0-9][0-9]$ ]]; then
    json="$(sed '$d' <<<"$existing")"
    user_uuid="$(jq -r '.response.uuid // .response.user.uuid // empty' <<<"$json")"
    user_name="$(jq -r '.response.username // .response.user.username // empty' <<<"$json")"
    if [[ "$user_name" == AUTO && -n "$user_uuid" ]]; then
      api_call PATCH /users/ "$(jq -nc --arg u "$user_uuid" --arg n "$username" --arg s "$SQUAD_UUID" \
        '{uuid:$u,username:$n,activeInternalSquads:[$s]}')" >/dev/null || true
    fi
    AUTO_SHORT_UUID="$(jq -r '.response.shortUuid // .response.user.shortUuid // empty' <<<"$json")"
    SUBSCRIPTION_URL="$(jq -r '.response.subscriptionUrl // .response.user.subscriptionUrl // empty' <<<"$json")"
    [[ -z "$SUBSCRIPTION_URL" && -n "$AUTO_SHORT_UUID" ]] && SUBSCRIPTION_URL="https://${DOMAIN_SUB}/${AUTO_SHORT_UUID}"
    persist_manager AUTO_SHORT_UUID "${AUTO_SHORT_UUID:-}"
    persist_manager SUBSCRIPTION_URL "${SUBSCRIPTION_URL:-}"
    ok "Пользователь $username уже есть. Подписка: ${SUBSCRIPTION_URL:-n/a}"
    return 0
  fi
  expire="$(date -u -d '+10 years' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -v+10y +%Y-%m-%dT%H:%M:%S.000Z)"
  body="$(jq -nc --arg u "$username" --arg e "$expire" --arg s "$SQUAD_UUID" \
    '{username:$u, status:"ACTIVE", expireAt:$e, trafficLimitBytes:0, activeInternalSquads:[$s]}')"
  raw="$(api_call POST /users/ "$body" "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  json="$(sed '$d' <<<"$raw")"
  if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
    warn "Пользователь $username не создан (HTTP ${code:-000}). Хосты, ноды и сквад уже привязаны автоматически."
    return 0
  fi
  AUTO_SHORT_UUID="$(jq -r '.response.shortUuid // .response.user.shortUuid // empty' <<<"$json")"
  SUBSCRIPTION_URL="$(jq -r '.response.subscriptionUrl // .response.user.subscriptionUrl // empty' <<<"$json")"
  [[ -z "$SUBSCRIPTION_URL" && -n "$AUTO_SHORT_UUID" ]] && SUBSCRIPTION_URL="https://${DOMAIN_SUB}/${AUTO_SHORT_UUID}"
  persist_manager AUTO_SHORT_UUID "${AUTO_SHORT_UUID:-}"
  persist_manager SUBSCRIPTION_URL "${SUBSCRIPTION_URL:-}"
  ok "Пользователь $username создан. Подписка выдаётся без правок в панели."
}

host_public_address(){
  local addr
  if [[ -n "${DOMAIN_REALITY:-}" ]]; then
    printf '%s' "$DOMAIN_REALITY"
    return 0
  fi
  if [[ "${MODE:-single}" == panel ]]; then
    addr="${EDGE_ADDRESS:-$(public_ip)}"
  else
    addr="$(public_ip)"
  fi
  printf '%s' "$addr"
}

bind_all(){
  local addr existing uuid name pname
  bind_nodes_to_profile
  ensure_internal_squad
  remove_default_profile_and_squads
  addr="$(host_public_address)"
  [[ -n "$addr" ]] || die "$(t err_host_addr)"
  existing="$(api_json "$(api_call GET /nodes/ '' "$API_JWT")")"
  if [[ "$(jq -r '[.response[]?.uuid] | length' <<<"$existing")" -eq 0 ]]; then
    create_protocol_hosts "$addr"
  else
    while IFS=$'\t' read -r uuid name; do
      [[ -n "$uuid" ]] || continue
      if [[ -n "${TARGET_NODE_UUID:-}" && "$uuid" != "$TARGET_NODE_UUID" ]]; then
        continue
      fi
      name="$(canonical_node_name "$name")"
      pname="$(profile_name_for_node "$name")"
      create_config_profile "$pname"
      HOST_NODES_JSON="$(jq -nc --arg u "$uuid" '[$u]')"
      create_protocol_hosts "$addr"
    done < <(jq -r '.response[]? | [(.uuid // ""), (.name // "node")] | @tsv' <<<"$existing")
    HOST_NODES_JSON=''
  fi
  create_auto_user
  restart_all_nodes
  persist_protocol_flags
  ok "$(t bind_ready "$BRAND")"
}

write_node_compose(){
  local root="$1" secret="$2"; mkdir -p "$root" /var/log/remnanode
  chmod 750 /var/log/remnanode
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
    volumes:
      - /var/log/remnanode:/var/log/remnanode
      - /dev/shm:/dev/shm
      - /etc/letsencrypt:/etc/letsencrypt:ro
    ulimits:
      nofile: {soft: 1048576, hard: 1048576}
YAML
  docker compose -f "$root/docker-compose.yml" config >/dev/null
  docker compose -f "$root/docker-compose.yml" pull -q
  docker compose -f "$root/docker-compose.yml" up -d
}

# --- Rezzosoft KVN: подготовка ноды под Hysteria2 / gRPC / xHTTP ---
# Источник: https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2
# Автор: Rezzosoft KVN. Конвертер: https://rezzosoft.ru/converter.html

rezzosoft_cert_domain(){
  local d="${DOMAIN_REALITY:-}"
  if [[ -n "$d" && -f "/etc/letsencrypt/live/$d/fullchain.pem" ]]; then
    printf '%s' "$d"
    return 0
  fi
  ls /etc/letsencrypt/live 2>/dev/null | grep -v README | head -1 || true
}

rezzosoft_sync_certs(){
  local domain cert key
  domain="$(rezzosoft_cert_domain)"
  [[ -n "$domain" ]] || { warn 'Rezzosoft: нет сертификата Lets Encrypt для /dev/shm.'; return 1; }
  cert="/etc/letsencrypt/live/${domain}/fullchain.pem"
  key="/etc/letsencrypt/live/${domain}/privkey.pem"
  [[ -f "$cert" && -f "$key" ]] || return 1
  cp -f "$cert" /dev/shm/hysteria_cert.pem
  cp -f "$key" /dev/shm/hysteria_key.pem
  chmod 644 /dev/shm/hysteria_cert.pem /dev/shm/hysteria_key.pem
  ok "Сертификаты $domain скопированы в /dev/shm (Hysteria2)."
}

write_hysteria_cert_helper(){
  cat > /usr/local/sbin/remnawave-hysteria-certs.sh <<'EOF2'
#!/usr/bin/env bash
set -eu
domain=""
if [[ -r /opt/remnawave/manager.env ]]; then
  domain="$(awk -F= '$1=="DOMAIN_REALITY"{print substr($0,index($0,"=")+1)}' /opt/remnawave/manager.env | tail -1)"
fi
if [[ -z "$domain" || ! -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]]; then
  domain="$(ls /etc/letsencrypt/live 2>/dev/null | grep -v README | head -1 || true)"
fi
[[ -n "$domain" && -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]] || exit 0
cp -f "/etc/letsencrypt/live/${domain}/fullchain.pem" /dev/shm/hysteria_cert.pem
cp -f "/etc/letsencrypt/live/${domain}/privkey.pem" /dev/shm/hysteria_key.pem
chmod 644 /dev/shm/hysteria_cert.pem /dev/shm/hysteria_key.pem
docker restart remnanode >/dev/null 2>&1 || true
EOF2
  chmod 700 /usr/local/sbin/remnawave-hysteria-certs.sh
}

rezzosoft_setup_cron(){
  # systemd timer, not user crontab: empty `crontab -` under set -e/pipefail
  # installs a zero-byte crontab ("-":0: bad minute) and aborts bind.
  write_hysteria_cert_helper
  cat > /etc/systemd/system/remnawave-hysteria-certs.service <<'EOF2'
[Unit]
Description=Copy Let's Encrypt certs to /dev/shm for Hysteria2
After=network-online.target docker.service
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/remnawave-hysteria-certs.sh
EOF2
  cat > /etc/systemd/system/remnawave-hysteria-certs.timer <<'EOF2'
[Unit]
Description=Daily Hysteria2 certificate sync
[Timer]
OnBootSec=30s
OnCalendar=*-*-* 04:00:00
Persistent=true
[Install]
WantedBy=timers.target
EOF2
  systemctl daemon-reload >/dev/null 2>&1 || true
  systemctl enable --now remnawave-hysteria-certs.timer >/dev/null 2>&1 || true
  systemctl start remnawave-hysteria-certs.service >/dev/null 2>&1 || true
  ok 'Hysteria2: сертификаты в /dev/shm через systemd (boot + ежедневно 04:00).'
}

ufw_toggle(){
  local spec="$1" on="${2:-0}"
  if [[ "$on" == 1 ]]; then
    ufw allow "$spec" >/dev/null 2>&1 || true
  else
    ufw delete allow "$spec" >/dev/null 2>&1 || true
  fi
}

remove_hysteria2_stack(){
  if [[ -f "$BASE/hysteria2/docker-compose.yml" ]]; then
    (cd "$BASE/hysteria2" && docker compose down) || true
  fi
  docker rm -f remnawave-hysteria2 >/dev/null 2>&1 || true
  systemctl disable --now remnawave-hysteria-certs.timer >/dev/null 2>&1 || true
  ok "$(t nt_hy2_off)"
}

apply_local_node_transports(){
  [[ $DRY_RUN -eq 1 ]] && { log "[DRY-RUN] local node transports $(protocol_summary)"; return 0; }
  log 'Rezzosoft KVN: порты, сертификаты и стек доп. протоколов на ноде.'
  ufw_toggle 443/udp "${HYSTERIA2:-0}"
  ufw_toggle 8443/udp "${HYSTERIA2:-0}"
  ufw_toggle 8443/tcp "${ENABLE_GRPC:-0}"
  ufw_toggle 4443/tcp "${ENABLE_XHTTP:-0}"
  if [[ ${HYSTERIA2:-0} -eq 1 ]]; then
    rezzosoft_sync_certs || warn 'Не удалось положить сертификаты в /dev/shm — Hysteria2 в профиле может не подняться.'
    rezzosoft_setup_cron
    install_hysteria2
  else
    remove_hysteria2_stack
  fi
  if docker inspect remnanode >/dev/null 2>&1; then
    docker restart remnanode >/dev/null || true
    sleep 2
  fi
  ok "$(t nt_local) $(protocol_summary)"
}

rezzosoft_prepare_node(){
  apply_local_node_transports
}

sync_node_transports(){
  local rewrite_compose="${1:-0}" root
  require_root
  snapshot_protocol_flags
  HYDRATE_QUIET=0 hydrate_install_state
  restore_protocol_flags
  already_installed || [[ -f "$ENV_FILE" ]] || [[ -f "$EDGE_ENV" ]] || die "$(t err_repair_no_install)"
  persist_protocol_flags
  if [[ "${MODE:-single}" != edge ]]; then
    bootstrap_auth
    generate_x25519
    bind_all
    prune_protocol_hosts
    if [[ "$rewrite_compose" == 1 && "${MODE:-single}" != panel && -n "${NODE_SECRET_KEY:-}" ]]; then
      root="$BASE/node"
      write_node_compose "$root" "$NODE_SECRET_KEY"
      configure_node_logs "$root"
    fi
  fi
  if [[ "${MODE:-single}" != panel ]]; then
    apply_local_node_transports || warn 'Rezzosoft: порты/certs не критичны.'
    if [[ "${MODE:-}" == edge ]]; then
      ok "$(t nt_edge_ok)"
    fi
  else
    ok "$(t nt_panel_hint)"
  fi
  persist_protocol_flags
  ok "$(t nt_done "$(protocol_summary)")"
}

apply_protocols(){
  require_root
  HYDRATE_QUIET=0 hydrate_install_state
  already_installed || [[ -f "$ENV_FILE" ]] || [[ -f "$EDGE_ENV" ]] || die "$(t err_repair_no_install)"
  if [[ ${PROTOCOLS_EXPLICIT:-0} -eq 0 ]]; then
    enable_all_protocols
  fi
  PROTOCOLS_EXPLICIT=1
  sync_node_transports 1
  show_credits
}

node_transports_menu(){
  local choice role
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  case "${MODE:-single}" in
    panel) role="$(t nt_role_panel)" ;;
    edge) role="$(t nt_role_edge)" ;;
    *) role="$(t nt_role_single)" ;;
  esac
  while true; do
    if [[ "${MODE:-single}" != edge ]]; then
      TARGET_NODE_UUID=''
      pick_target_node || return 0
    fi
    while true; do
      echo
      echo "${U_BLUE}${U_BOLD}$(t nt_title)${U_RESET}"
      echo "${U_SKY}$(t nt_now "$(protocol_summary)")${U_RESET}"
      echo "${U_DIM}${role}${U_RESET}"
      echo "${U_DIM}$(t nt_split)${U_RESET}"
      echo "$(t nt_1)"
      echo "$(t nt_2)"
      echo "$(t nt_3)"
      echo "$(t nt_4)"
      echo "$(t nt_5)"
      echo "$(t nt_6)"
      echo "$(t nt_7)"
      echo "$(t nt_8)"
      echo "$(t nt_9)"
      echo "$(t nt_0)"
      echo "$(t nt_q)"
      read -r -p "$(t prompt_choice)" choice
      case "$choice" in
        1) set_transport hysteria2 1; sync_node_transports; print_node_apply_hint ;;
        2) set_transport grpc 1; sync_node_transports; print_node_apply_hint ;;
        3) set_transport xhttp 1; sync_node_transports; print_node_apply_hint ;;
        4) set_transport all 1; sync_node_transports; print_node_apply_hint ;;
        5) set_transport hysteria2 0; sync_node_transports; print_node_apply_hint ;;
        6) set_transport grpc 0; sync_node_transports; print_node_apply_hint ;;
        7) set_transport xhttp 0; sync_node_transports; print_node_apply_hint ;;
        8) set_transport all 0; sync_node_transports; print_node_apply_hint ;;
        9) PROTOCOLS_EXPLICIT=1; sync_node_transports ;;
        0|'')
          [[ "${MODE:-single}" == edge ]] && return 0
          break
          ;;
        q|Q)
          return 0
          ;;
        *) echo "$(t err_unknown_item)" ;;
      esac
    done
  done
}

node_transports_cli(){
  local action="${1:-menu}" proto="${2:-}" node="${3:-}"
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  if [[ -n "$node" && "$node" != all && "$node" != 0 ]]; then
    TARGET_NODE_UUID="$node"
  elif [[ "$node" == all || "$node" == 0 ]]; then
    TARGET_NODE_UUID=''
  fi
  case "$action" in
    menu|'') node_transports_menu ;;
    apply)
      PROTOCOLS_EXPLICIT=1
      sync_node_transports
      ;;
    reality-only|reality)
      set_transport all 0
      sync_node_transports
      ;;
    add|enable|on)
      [[ -n "$proto" ]] || die "$(t err_nt_proto '?')"
      set_transport "$proto" 1
      sync_node_transports
      ;;
    remove|rm|del|delete|disable|off)
      [[ -n "$proto" ]] || die "$(t err_nt_proto '?')"
      set_transport "$proto" 0
      sync_node_transports
      ;;
    status)
      echo "$(protocol_summary)"
      ;;
    *) die "$(t err_nt_cmd)" ;;
  esac
}

show_credits(){
  cat <<EOF2

$(t credits_title)
$(t credits_owner "$VERSION")
$(t credits_repo "$PROJECT_URL")

$(t credits_added)
$(t credits_rez)
    https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2
$(t credits_conv "$CONVERTER_URL")
$(t credits_eg)
    https://github.com/eGamesAPI/remnawave-reverse-proxy
$(t credits_dig)
    https://github.com/DigneZzZ/remnawave-scripts
$(t credits_refresh)

EOF2
}

compose_action(){
  local action="$1" d
  for d in "$BASE" "$BASE/subscription" "$BASE/node" "$EDGE_BASE/node" "$BASE/hysteria2" "$BASE/monitoring"; do
    [[ -f "$d/docker-compose.yml" ]] || continue
    (cd "$d" && docker compose "$action") || true
  done
}

svc_logs(){
  local name="${1:-}"
  if [[ -n "$name" ]]; then
    docker logs --tail 100 -f "$name"
    return 0
  fi
  docker ps --format '{{.Names}}' | grep -E 'remnawave|remnanode|subscription|hysteria' || true
  echo
  echo "$(t logs_hint)"
}

install_cli(){
  local dest=/usr/local/bin/remnawave-manager src
  src="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "$0")"
  install -m 0755 "$src" "$dest"
  ok "$(t cli_ok "$dest")"
}

# eGames-style cookie-stealth for the panel (opt-in: PANEL_STEALTH=1)
enable_panel_stealth(){
  local key="${PANEL_STEALTH_KEY:-$(rand 16)}"
  [[ -f /etc/nginx/conf.d/remnawave-web.conf ]] || die 'Сначала установите панель.'
  persist_manager PANEL_STEALTH_KEY "$key"
  python3 - "$key" <<'PY'
import pathlib, sys
key = sys.argv[1]
p = pathlib.Path("/etc/nginx/conf.d/remnawave-web.conf")
s = p.read_text()
if "set $panel_ok 0;" in s:
    raise SystemExit(0)
inject = (
    "  set $panel_ok 0;\n"
    f"  if ($arg_{key} = {key}) {{ set $panel_ok 1; }}\n"
    f"  if ($cookie_{key} = {key}) {{ set $panel_ok 1; }}\n"
    "  if ($panel_ok != 1) { return 404; }\n"
    f'  add_header Set-Cookie "{key}={key}; Path=/; HttpOnly; Secure; SameSite=Lax" always;\n'
)
s = s.replace(
    "  include /etc/nginx/snippets/remnawave-ssl.conf;\n  location /api/auth/login",
    "  include /etc/nginx/snippets/remnawave-ssl.conf;\n" + inject + "  location /api/auth/login",
    1,
)
p.write_text(s)
PY
  nginx_apply
  ok "Скрытый вход в панель: https://${DOMAIN_PANEL}/auth/login?${key}=${key}"
}

ask_protocols(){
  local choice
  if [[ ${PROTOCOLS_EXPLICIT:-0} -eq 1 ]]; then
    [[ $DRY_RUN -eq 1 ]] && return 0
    persist_protocol_flags
    return 0
  fi
  echo
  echo "$(t proto_title)"
  echo "$(t proto_1)"
  echo "$(t proto_2)"
  echo "$(t proto_3)"
  echo "$(t proto_4)"
  echo "$(t proto_5)"
  if [[ $AUTO_YES -eq 1 ]]; then
    choice="${PROTOCOLS_CHOICE:-5}"
  else
    read -r -p "$(t prompt_protocols)" choice
    choice="${choice:-5}"
  fi
  case "$choice" in
    1) HYSTERIA2=0; ENABLE_GRPC=0; ENABLE_XHTTP=0 ;;
    2) HYSTERIA2=1; ENABLE_GRPC=0; ENABLE_XHTTP=0 ;;
    3) ENABLE_GRPC=1 ;;
    4) ENABLE_XHTTP=1 ;;
    *) enable_all_protocols ;;
  esac
  PROTOCOLS_EXPLICIT=1
  [[ $DRY_RUN -eq 1 ]] && return 0
  persist_protocol_flags
}

nginx_apply(){
  if ! nginx -t >/dev/null; then
    nginx -t
    die 'Проверка nginx не пройдена.'
  fi
  systemctl reload nginx
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
  [[ "${NGINX_SKIP_RELOAD:-0}" == 1 ]] || nginx_apply
}

issue_cert(){
  local domain="$1" email="$2"
  mkdir -p /var/www/html/.well-known/acme-challenge
  if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" && -f "/etc/letsencrypt/live/$domain/privkey.pem" ]]; then return 0; fi
  if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    apt-get install -y -qq python3-certbot-dns-cloudflare >/dev/null
    mkdir -p /root/.secrets
    printf 'dns_cloudflare_api_token = %s\n' "$CLOUDFLARE_API_TOKEN" > /root/.secrets/cloudflare.ini
    chmod 600 /root/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
      --non-interactive --agree-tos --email "$email" --key-type ecdsa -d "$domain"
    return 0
  fi
  certbot certonly --webroot -w /var/www/html --non-interactive --agree-tos --email "$email" --key-type ecdsa -d "$domain"
}

migrate_ssl_params_includes(){
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    sed -i 's#include /etc/nginx/conf.d/ssl-params.conf;#include /etc/nginx/snippets/remnawave-ssl.conf;#g' "$f"
  done < <(grep -Rl --include='*.conf' 'ssl-params.conf' /etc/nginx 2>/dev/null || true)
}

tls_params(){
  mkdir -p /etc/nginx/snippets /etc/nginx/conf.d
  # 25.1.12 repair deleted this file while reality-site.conf still included it.
  # Recreate a no-op stub immediately so nginx -t cannot fail on a missing include.
  cat > /etc/nginx/conf.d/ssl-params.conf <<'EOF2'
# Compatibility stub. Leftover vhosts may still include this path.
# TLS settings live in /etc/nginx/snippets/remnawave-ssl.conf
EOF2
  # ssl-params.conf in conf.d/ is auto-included by Ubuntu. Keep it empty of
  # ssl_protocols so vhost snippet includes do not duplicate TLSv1.2/1.3.
  cat > /etc/nginx/conf.d/00-remnawave-http.conf <<'EOF2'
proxy_headers_hash_max_size 1024;
proxy_headers_hash_bucket_size 128;
map $http_upgrade $connection_upgrade {
  default upgrade;
  "" close;
}
EOF2
  cat > /etc/nginx/snippets/remnawave-ssl.conf <<'EOF2'
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
  # Official Remnawave reverse-proxy headers. Ubuntu proxy_params uses
  # $scheme/$http_host and is not enough for ProxyCheckMiddleware (panel and
  # subscription-page destroy the socket without X-Forwarded-For + proto=https).
  cat > /etc/nginx/snippets/remnawave-proxy.conf <<'EOF2'
proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port 443;
proxy_set_header X-Remnawave-Client-Type browser;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_read_timeout 60s;
proxy_send_timeout 60s;
EOF2
  migrate_ssl_params_includes
  cat > /etc/nginx/conf.d/ssl-params.conf <<'EOF2'
# Compatibility stub. Leftover vhosts may still include this path.
# TLS settings live in /etc/nginx/snippets/remnawave-ssl.conf
EOF2
}

write_panel_vhosts(){
  cat > /etc/nginx/conf.d/remnawave-web.conf <<EOF2
server {
  listen 127.0.0.1:9443 ssl http2;
  server_name ${DOMAIN_PANEL};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_PANEL}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_PANEL}/privkey.pem;
  include /etc/nginx/snippets/remnawave-ssl.conf;
  location /api/auth/login { limit_req zone=login_limit burst=3 nodelay; proxy_pass http://127.0.0.1:3000; include /etc/nginx/snippets/remnawave-proxy.conf; }
  location /api/ { limit_req zone=api_limit burst=30 nodelay; proxy_pass http://127.0.0.1:3000; include /etc/nginx/snippets/remnawave-proxy.conf; }
  location / { proxy_pass http://127.0.0.1:3000; include /etc/nginx/snippets/remnawave-proxy.conf; }
}
server {
  listen 127.0.0.1:9443 ssl http2;
  server_name ${DOMAIN_SUB};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_SUB}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_SUB}/privkey.pem;
  include /etc/nginx/snippets/remnawave-ssl.conf;
  location / { proxy_pass http://127.0.0.1:3010; include /etc/nginx/snippets/remnawave-proxy.conf; }
}
EOF2
}

write_sni_router(){
  local include_reality="${1:-1}" reality_map=''
  mkdir -p /var/www/reality-site
  if [[ "$include_reality" == 1 && -n "${DOMAIN_REALITY:-}" ]]; then
    cat > /etc/nginx/conf.d/reality-site.conf <<EOF2
server {
  listen 127.0.0.1:9450 ssl http2;
  server_name ${DOMAIN_REALITY};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_REALITY}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_REALITY}/privkey.pem;
  include /etc/nginx/snippets/remnawave-ssl.conf;
  root /var/www/reality-site;
  location / { try_files \$uri \$uri/ /index.html; }
}
EOF2
    reality_map="    ${DOMAIN_REALITY} 127.0.0.1:8444;"
  fi
  cat > "$STREAM_CONF" <<EOF2
stream {
  map \$ssl_preread_server_name \$remna_backend {
    default 127.0.0.1:9444;
${reality_map}
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
  write_reject_vhost '127.0.0.1:9444'
  grep -Fq "include $STREAM_CONF;" /etc/nginx/nginx.conf || sed -i "/^http {/i include $STREAM_CONF;" /etc/nginx/nginx.conf
  [[ "${NGINX_SKIP_RELOAD:-0}" == 1 ]] || nginx_apply
}

sync_sub_public_domain(){
  [[ -f "$BASE/.env" && -n "${DOMAIN_SUB:-}" ]] || return 0
  local current
  current="$(awk -F= '$1=="SUB_PUBLIC_DOMAIN"{print substr($0,index($0,"=")+1)}' "$BASE/.env" | tail -1)"
  current="${current%\"}"
  current="${current#\"}"
  [[ "$current" == "$DOMAIN_SUB" ]] && return 0
  log "SUB_PUBLIC_DOMAIN: ${current:-unset} -> ${DOMAIN_SUB}"
  upsert_kv "$BASE/.env" SUB_PUBLIC_DOMAIN "$DOMAIN_SUB"
  (cd "$BASE" && docker compose up -d --no-deps --force-recreate remnawave)
  wait_api
}

nginx_panel_ready(){
  [[ -n "${DOMAIN_PANEL:-}" ]] || return 1
  [[ -f /etc/nginx/conf.d/remnawave-web.conf ]] || return 1
  [[ -f "/etc/letsencrypt/live/${DOMAIN_PANEL}/fullchain.pem" ]] || return 1
  ss -lnt 2>/dev/null | grep -qE ':443[[:space:]]' || return 1
}

probe_http_code(){
  local url="$1" code; shift || true
  code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 4 "$@" "$url" 2>/dev/null || true)"
  [[ "$code" =~ ^[0-9]{3}$ ]] || code=000
  printf '%s' "$code"
}

subscription_panel_url(){
  if nginx_panel_ready; then
    printf 'https://%s' "$DOMAIN_PANEL"
  else
    printf 'http://remnawave:3000'
  fi
}

wait_subscription(){
  local code i max=30
  for i in $(seq 1 "$max"); do
    code="$(probe_http_code http://127.0.0.1:3010/ \
      -H 'X-Forwarded-For: 127.0.0.1' \
      -H 'X-Forwarded-Proto: https' \
      -H "X-Forwarded-Host: ${DOMAIN_SUB:-localhost}" \
      -H "Host: ${DOMAIN_SUB:-localhost}")"
    if [[ "$code" =~ ^[23][0-9][0-9]$ ]]; then
      ok "Subscription page отвечает на 127.0.0.1:3010 (HTTP $code)."
      return 0
    fi
    code="$(probe_http_code http://127.0.0.1:3010/)"
    if [[ "$code" =~ ^[23][0-9][0-9]$ ]]; then
      ok "Subscription page отвечает на 127.0.0.1:3010 (HTTP $code)."
      return 0
    fi
    if (( i % 5 == 0 || i == 1 )); then
      log "$(t wait_sub_try "$i" "$max" "$code")"
    fi
    sleep 2
  done
  docker ps -a --filter name=remnawave-subscription-page --format 'table {{.Names}}\t{{.Status}}' | tee -a "$LOG" >/dev/null || true
  docker logs --tail 40 remnawave-subscription-page 2>&1 | tee -a "$LOG" >/dev/null || true
  warn "$(t wait_sub_fail)"
  return 1
}

install_subscription(){
  [[ -n "${SUB_API_TOKEN:-}" && "$SUB_API_TOKEN" != null ]] || die 'install_subscription: нет SUB_API_TOKEN.'
  local panel_url
  panel_url="$(subscription_panel_url)"
  mkdir -p "$BASE/subscription"
  # Official bundled install: empty CUSTOM_SUB_PREFIX so https://sub.example.com/ works.
  # After nginx is up, talk to the panel via https://DOMAIN_PANEL so ProxyCheckMiddleware
  # sees X-Forwarded-* from host nginx (direct http://remnawave:3000 is socket-destroyed).
  cat > "$BASE/subscription/.env" <<EOF2
APP_PORT=3010
REMNAWAVE_PANEL_URL=${panel_url}
REMNAWAVE_API_TOKEN=$SUB_API_TOKEN
CUSTOM_SUB_PREFIX=
MARZBAN_LEGACY_LINK_ENABLED=false
TRUST_PROXY=1
EOF2
  chmod 600 "$BASE/subscription/.env"
  cat > "$BASE/subscription/docker-compose.yml" <<EOF2
services:
  remnawave-subscription-page:
    image: remnawave/subscription-page:latest
    container_name: remnawave-subscription-page
    hostname: remnawave-subscription-page
    restart: always
    env_file: .env
    ports: ["127.0.0.1:3010:3010"]
    extra_hosts:
      - "host.docker.internal:host-gateway"
      - "${DOMAIN_PANEL:-panel.local}:host-gateway"
      - "${DOMAIN_SUB:-sub.local}:host-gateway"
    networks: [remnawave-network]
networks:
  remnawave-network:
    external: true
    name: remnawave-network
EOF2
  docker network inspect remnawave-network >/dev/null 2>&1 || docker network create remnawave-network >/dev/null
  docker compose -f "$BASE/subscription/docker-compose.yml" config >/dev/null
  docker compose -f "$BASE/subscription/docker-compose.yml" pull -q
  docker compose -f "$BASE/subscription/docker-compose.yml" up -d --remove-orphans --force-recreate --wait --wait-timeout 120
}

ensure_subscription(){
  [[ "${MODE:-single}" == edge ]] && return 0
  [[ -n "${DOMAIN_SUB:-}" ]] || return 0
  [[ $DRY_RUN -eq 1 ]] && { log '[DRY-RUN] subscription-page: token, .env, compose, wait :3010'; return 0; }
  bootstrap_auth
  create_subscription_token
  sync_sub_public_domain
  install_subscription
  wait_subscription || return 1
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
    command: ["run","-c","/etc/sing-box/config.json"]
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
    static_configs: [{targets: ['host.docker.internal:9100']}]
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
if [[ -f /opt/remnawave/docker-compose.yml ]]; then
  panel_host="$(awk -F= '$1=="DOMAIN_PANEL"{print substr($0,index($0,"=")+1)}' /opt/remnawave/manager.env 2>/dev/null | tail -1)"
  panel_host="${panel_host:-localhost}"
  if ! curl -fsS --max-time 5 \
    -H 'X-Forwarded-For: 127.0.0.1' \
    -H 'X-Forwarded-Proto: https' \
    -H "X-Forwarded-Host: ${panel_host}" \
    -H "Host: ${panel_host}" \
    http://127.0.0.1:3000/api/auth/status >/dev/null 2>&1; then
    docker compose -f /opt/remnawave/docker-compose.yml restart >/dev/null 2>&1 || true
  fi
fi
if [[ -f /opt/remnawave/subscription/docker-compose.yml ]]; then
  sub_host="$(awk -F= '$1=="DOMAIN_SUB"{print substr($0,index($0,"=")+1)}' /opt/remnawave/manager.env 2>/dev/null | tail -1)"
  sub_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
    -H 'X-Forwarded-For: 127.0.0.1' \
    -H 'X-Forwarded-Proto: https' \
    -H "Host: ${sub_host:-localhost}" \
    http://127.0.0.1:3010/ 2>/dev/null || echo 000)"
  if [[ ! "$sub_code" =~ ^[23][0-9][0-9]$ ]]; then
    docker compose -f /opt/remnawave/subscription/docker-compose.yml up -d >/dev/null 2>&1 || true
  fi
fi
systemctl is-active --quiet nginx || systemctl restart nginx || true
if [[ -x /usr/local/sbin/remnawave-health-notify.sh ]]; then
  /usr/local/sbin/remnawave-health-notify.sh || true
fi
EOF2
  chmod 700 /usr/local/sbin/remnawave-healthcheck.sh
  write_health_notify_script
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
if [[ -x /usr/local/sbin/remnawave-hysteria-certs.sh ]]; then
  /usr/local/sbin/remnawave-hysteria-certs.sh || true
fi
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
  write_hysteria_cert_helper
  if [[ ${HYSTERIA2:-0} -eq 1 ]]; then
    rezzosoft_setup_cron || true
  fi
}

configure_remote_backup(){
  [[ -n "${BACKUP_REMOTE:-}" ]] || return 0
  persist_manager BACKUP_REMOTE "$BACKUP_REMOTE"
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
Node UUID: ${NODE_UUID:-n/a}
Squad ${BRAND}: ${SQUAD_UUID:-n/a}
User ${BRAND} short UUID: ${AUTO_SHORT_UUID:-n/a}
Subscription URL: ${SUBSCRIPTION_URL:-n/a}
Reality public key: ${REALITY_PUBLIC_KEY}
Reality short ID: ${REALITY_SHORT_ID}
Hysteria2 password: ${HYSTERIA2_PASSWORD:-disabled}
EOF2
  chmod 600 "$CREDS_FILE"
}

finish_config(){
  persist_manager ADMIN_USERNAME "${ADMIN_USERNAME:-}"
  persist_manager ADMIN_PASSWORD "${ADMIN_PASSWORD:-}"
  persist_manager SUB_API_TOKEN "${SUB_API_TOKEN:-}"
  persist_manager NODE_SECRET_KEY "${NODE_SECRET_KEY:-}"
  persist_manager PROFILE_UUID "${PROFILE_UUID:-}"
  persist_manager INBOUND_UUID "${INBOUND_UUID:-}"
  persist_manager HOST_UUID "${HOST_UUID:-}"
  persist_manager NODE_UUID "${NODE_UUID:-}"
  persist_manager SQUAD_UUID "${SQUAD_UUID:-}"
  persist_manager AUTO_SHORT_UUID "${AUTO_SHORT_UUID:-}"
  persist_manager SUBSCRIPTION_URL "${SUBSCRIPTION_URL:-}"
  persist_manager REALITY_PUBLIC_KEY "${REALITY_PUBLIC_KEY:-}"
  persist_manager REALITY_SHORT_ID "${REALITY_SHORT_ID:-}"
  persist_manager HYSTERIA2 "${HYSTERIA2:-0}"
  persist_manager ENABLE_GRPC "${ENABLE_GRPC:-0}"
  persist_manager ENABLE_XHTTP "${ENABLE_XHTTP:-0}"
  persist_manager RW_LANG "${RW_LANG:-ru}"
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
  set_gzip
  write_panel_vhosts
  write_sni_router 1
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
  local p
  while read -r p; do
    [[ -n "$p" ]] || continue
    ufw delete allow "$p/tcp" >/dev/null 2>&1 || true
    ufw allow from "$ADMIN_IP" to any port "$p" proto tcp >/dev/null
  done < <(ssh_ports)
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
  persist_manager TELEGRAM_BOT_TOKEN "$TELEGRAM_BOT_TOKEN"
  persist_manager TELEGRAM_CHAT_ID "$TELEGRAM_CHAT_ID"
  persist_manager TELEGRAM_THREAD_ID "${TELEGRAM_THREAD_ID:-}"
  persist_manager TELEGRAM_ALERTS 1
  TELEGRAM_ALERTS=1
  write_health_notify_script
  ensure_health_notify_hook
  telegram_send "Remnawave Manager $VERSION: Telegram alerts enabled on $(hostname)"
}

install_selfsteal(){
  local site='/var/www/reality-site' tpl="${SELFSTEAL_TEMPLATE:-corgi}"
  mkdir -p "$site"
  rm -f "$site/index.html" "$site/about.html" "$site/breeds.html" "$site/contact.html" "$site/styles.css"
  case "$tpl" in
    corgi)
      cat > "$site/styles.css" <<'EOF_SITE'
:root{--ink:#2b1d12;--muted:#6b5344;--paper:#fbf6ee;--card:#fffaf3;--accent:#c45c26;--leaf:#2f6b4f;--line:#ead9c6}
*{box-sizing:border-box}html,body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.6 "Segoe UI",system-ui,sans-serif}
a{color:var(--leaf);text-decoration:none}a:hover{text-decoration:underline}
header{background:linear-gradient(180deg,#f3e2c9,#fbf6ee);border-bottom:1px solid var(--line)}
.wrap{max-width:980px;margin:0 auto;padding:24px}
nav{display:flex;gap:18px;flex-wrap:wrap;align-items:center}
.brand{font-weight:800;letter-spacing:.02em;color:var(--ink);font-size:22px}
.hero{display:grid;grid-template-columns:1.2fr .8fr;gap:32px;align-items:center;padding:48px 0}
h1{font-size:44px;line-height:1.15;margin:0 0 12px}h2{font-size:28px}
.card{background:var(--card);border:1px solid var(--line);border-radius:18px;padding:22px;box-shadow:0 10px 30px rgba(43,29,18,.05)}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin:28px 0}
.btn{display:inline-block;background:var(--accent);color:#fff;padding:10px 16px;border-radius:999px;font-weight:700}
.btn:hover{text-decoration:none;filter:brightness(1.05)}
svg.corgi{width:100%;max-width:340px;height:auto}
footer{color:var(--muted);font-size:14px;padding:40px 0 64px}
@media (max-width:800px){.hero{grid-template-columns:1fr;padding:24px 0}h1{font-size:34px}}
EOF_SITE
      cat > "$site/index.html" <<'EOF_SITE'
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Corgi Lusi — питомник вельш-корги</title>
<meta name="description" content="Corgi Lusi — домашний питомник вельш-корги пемброк. Щенки, взрослые собаки, уход и история породы.">
<link rel="stylesheet" href="/styles.css">
</head>
<body>
<header>
  <div class="wrap">
    <nav>
      <a class="brand" href="/">Corgi Lusi</a>
      <a href="/about.html">О питомнике</a>
      <a href="/breeds.html">Порода</a>
      <a href="/contact.html">Контакты</a>
    </nav>
    <section class="hero">
      <div>
        <p style="color:var(--accent);font-weight:700;margin:0 0 8px">Вельш-корги пемброк</p>
        <h1>Маленькие пастухи с большим характером</h1>
        <p>Corgi Lusi — семейный питомник. Мы рассказываем о корги, растим здоровых собак и делимся советами по уходу, питанию и воспитанию.</p>
        <p><a class="btn" href="/about.html">Познакомиться</a></p>
      </div>
      <div class="card" aria-hidden="true">
        <svg class="corgi" viewBox="0 0 280 220" xmlns="http://www.w3.org/2000/svg">
          <rect width="280" height="220" rx="24" fill="#f3e2c9"/>
          <ellipse cx="150" cy="150" rx="78" ry="42" fill="#d38a3a"/>
          <ellipse cx="150" cy="128" rx="62" ry="48" fill="#e0a25a"/>
          <ellipse cx="118" cy="118" rx="18" ry="14" fill="#fff6ea"/>
          <ellipse cx="182" cy="118" rx="18" ry="14" fill="#fff6ea"/>
          <circle cx="124" cy="116" r="5" fill="#2b1d12"/>
          <circle cx="176" cy="116" r="5" fill="#2b1d12"/>
          <ellipse cx="150" cy="132" rx="8" ry="6" fill="#2b1d12"/>
          <path d="M118 78 98 42 132 72z" fill="#c45c26"/>
          <path d="M182 78 210 40 168 72z" fill="#c45c26"/>
          <path d="M92 148c8 22 22 34 38 36" stroke="#9a5a28" stroke-width="10" fill="none" stroke-linecap="round"/>
          <path d="M208 148c-6 22-18 34-34 38" stroke="#9a5a28" stroke-width="10" fill="none" stroke-linecap="round"/>
        </svg>
      </div>
    </section>
  </div>
</header>
<main class="wrap">
  <section class="grid">
    <article class="card"><h2>Характер</h2><p>Корги умные, контактные и чуть упрямые. Им нужны задачи, прогулки и семья рядом — тогда это лучшие компаньоны.</p></article>
    <article class="card"><h2>Уход</h2><p>Двойная шерсть линяет дважды в год. Расчёсывание, контроль веса и бережная нагрузка на спину важнее любой косметики.</p></article>
    <article class="card"><h2>История</h2><p>Порода из Уэльса пасла скот, покусывая пятки коровам. Короткие ноги — не недостаток, а рабочий инструмент.</p></article>
  </section>
</main>
<footer class="wrap"><p>© Corgi Lusi. Статьи о вельш-корги, уходе и жизни с пастушьей собакой в городе.</p></footer>
</body></html>
EOF_SITE
      cat > "$site/about.html" <<'EOF_SITE'
<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>О питомнике — Corgi Lusi</title><link rel="stylesheet" href="/styles.css"></head>
<body><header><div class="wrap"><nav><a class="brand" href="/">Corgi Lusi</a><a href="/about.html">О питомнике</a><a href="/breeds.html">Порода</a><a href="/contact.html">Контакты</a></nav></div></header>
<main class="wrap"><article class="card"><h1>О питомнике</h1><p>Lusi — домашняя линия вельш-корги пемброк. Мы не гонимся за количеством помётов: важны здоровье, социализация и честный рассказ о породе.</p><p>Гостей принимаем по записи. Перед щенком всегда говорим о спине, весе, линьке и том, что корги — пастух, а не диванная игрушка.</p></article></main>
<footer class="wrap"><p>© Corgi Lusi</p></footer></body></html>
EOF_SITE
      cat > "$site/breeds.html" <<'EOF_SITE'
<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Порода — Corgi Lusi</title><link rel="stylesheet" href="/styles.css"></head>
<body><header><div class="wrap"><nav><a class="brand" href="/">Corgi Lusi</a><a href="/about.html">О питомнике</a><a href="/breeds.html">Порода</a><a href="/contact.html">Контакты</a></nav></div></header>
<main class="wrap"><article class="card"><h1>Вельш-корги пемброк</h1><p>Пемброк отличается от кардигана более лёгким сложением и обычно короткохвост. Обе разновидности — пастухи, обе склонны к набору веса.</p><p>На площадке корги любит контроль: следит за детьми, велосипедами и чужими собаками. Это не агрессия, а работа, которую нужно направлять.</p></article></main>
<footer class="wrap"><p>© Corgi Lusi</p></footer></body></html>
EOF_SITE
      cat > "$site/contact.html" <<'EOF_SITE'
<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Контакты — Corgi Lusi</title><link rel="stylesheet" href="/styles.css"></head>
<body><header><div class="wrap"><nav><a class="brand" href="/">Corgi Lusi</a><a href="/about.html">О питомнике</a><a href="/breeds.html">Порода</a><a href="/contact.html">Контакты</a></nav></div></header>
<main class="wrap"><article class="card"><h1>Контакты</h1><p>Пишите на почту питомника или оставьте заявку через форму на этой странице. Мы отвечаем в рабочие дни и не продаём щенков «в один клик».</p><p>Экскурсии на территорию — только после короткого созвона: так спокойнее собакам.</p></article></main>
<footer class="wrap"><p>© Corgi Lusi</p></footer></body></html>
EOF_SITE
      ;;
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
    *) die 'Шаблон маскировки: corgi|simple|business|nothing' ;;
  esac
  ok "SelfSteal template: $tpl."
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
mount='      - ./xray-custom:/usr/local/bin/xray\n'
if mount in s:
    raise SystemExit(0)
log_mount='      - /var/log/remnanode:/var/log/remnanode\n'
if log_mount in s:
    s=s.replace(log_mount, log_mount+mount, 1)
else:
    needle='    env_file: .env\n'
    if needle not in s: raise SystemExit('compose anchor not found')
    s=s.replace(needle, needle+'    volumes:\n'+mount,1)
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

addon_catalog(){
  cat <<'EOF'
remnawave|DigneZzZ|https://github.com/DigneZzZ/remnawave-scripts/raw/main/remnawave.sh|remnawave.sh|https://github.com/DigneZzZ/remnawave-scripts
remnanode|DigneZzZ|https://github.com/DigneZzZ/remnawave-scripts/raw/main/remnanode.sh|remnanode.sh|https://github.com/DigneZzZ/remnawave-scripts
selfsteal|DigneZzZ|https://github.com/DigneZzZ/remnawave-scripts/raw/main/selfsteal.sh|selfsteal.sh|https://github.com/DigneZzZ/remnawave-scripts
wtm|DigneZzZ|https://github.com/DigneZzZ/remnawave-scripts/raw/main/wtm.sh|wtm.sh|https://github.com/DigneZzZ/remnawave-scripts
netbird|DigneZzZ|https://github.com/DigneZzZ/remnawave-scripts/raw/main/netbird.sh|netbird.sh|https://github.com/DigneZzZ/remnawave-scripts
egames|eGamesAPI|https://github.com/eGamesAPI/remnawave-reverse-proxy/raw/main/install_remnawave.sh|remnawave_reverse.sh|https://github.com/eGamesAPI/remnawave-reverse-proxy
EOF
}

install_upstream_addon(){
  local addon="$1" id author url script repo
  while IFS='|' read -r id author url script repo; do
    [[ "$id" == "$addon" ]] || continue
    mkdir -p "$ADDONS_DIR"
    download_upstream "$url" "$ADDONS_DIR/$script" || die "Не удалось загрузить модуль $addon ни с GitHub, ни через jsDelivr."
    chmod 700 "$ADDONS_DIR/$script"
    ok "Подключаю модуль $author / $id (авторство сохранено: $repo)."
    if [[ "$addon" == remnawave || "$addon" == remnanode ]]; then
      "$ADDONS_DIR/$script" @ install-script
    else
      "$ADDONS_DIR/$script"
    fi
    return 0
  done < <(addon_catalog)
  die "$(t err_addon)"
}

write_addon_credits(){
  mkdir -p "$ADDONS_DIR"
  cat > "$ADDONS_DIR/AUTHORS.txt" <<EOF2
Корги Люси / Corgi Lusi — Remnawave Manager $VERSION
$PROJECT_URL

Community modules. Original authorship is kept.
Rezzosoft KVN  https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2
  converter: $CONVERTER_URL
eGamesAPI      https://github.com/eGamesAPI/remnawave-reverse-proxy
DigneZzZ       https://github.com/DigneZzZ/remnawave-scripts

Refreshed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF2
  chmod 644 "$ADDONS_DIR/AUTHORS.txt"
}

refresh_community_modules(){
  local id author url script repo ok_n=0
  mkdir -p "$ADDONS_DIR"
  write_addon_credits
  echo "$(t comm_keep)"
  ok "Rezzosoft KVN уже в этом скрипте. Конвертер: $CONVERTER_URL"
  while IFS='|' read -r id author url script repo; do
    [[ -n "$id" ]] || continue
    if download_upstream "$url" "$ADDONS_DIR/$script"; then
      chmod 700 "$ADDONS_DIR/$script"
      ok "$author / $id → $ADDONS_DIR/$script"
      printf '  %s  %s  %s\n' "$author" "$id" "$repo" >> "$ADDONS_DIR/AUTHORS.txt"
      ok_n=$((ok_n + 1))
    else
      warn "Не удалось обновить $id ($author)."
    fi
  done < <(addon_catalog)
  persist_manager COMMUNITY_REFRESHED_AT "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ok "$(t comm_done "$ADDONS_DIR/AUTHORS.txt") ($ok_n)"
}

http_first_redirect(){
  curl -fsSI --connect-timeout 10 --max-time 25 --retry 2 --retry-all-errors \
    -A 'remnawave-manager' \
    -o /dev/null -w '%{redirect_url}' \
    "$1" 2>/dev/null || true
}

tag_from_github_url(){
  local s="${1:-}" t=''
  s="${s%%$'\r'}"
  if [[ "$s" == *'/releases/tag/'* ]]; then
    t="${s##*/releases/tag/}"
  elif [[ "$s" == *'/download/v'* ]]; then
    t="${s#*/download/v}"
  fi
  t="${t%%/*}"
  t="${t%%[\?#]*}"
  normalize_tag "$t"
}

download_self_script(){
  local dest="$1" url
  for url in "$SELF_UPDATE_URL" "$JSDELIVR_LATEST_URL"; do
    if curl -fL --retry 5 --retry-all-errors --connect-timeout 10 --max-time 120 \
         -A 'remnawave-manager' -o "$dest" "$url" 2>/dev/null \
       && bash -n "$dest" 2>/dev/null; then
      return 0
    fi
    rm -f "$dest"
  done
  return 1
}

self_update(){
  local tmp dest cli=/usr/local/bin/remnawave-manager
  dest="$(script_path)"
  tmp="$(mktemp)"
  download_self_script "$tmp" || { rm -f "$tmp"; die "$(t err_download "$SELF_UPDATE_URL")"; }
  install -m 0755 "$tmp" "$dest"
  if [[ -x "$cli" && "$cli" != "$dest" ]]; then
    install -m 0755 "$tmp" "$cli" || true
  fi
  rm -f "$tmp"
  ok "$(t self_ok)"
  # IFS is $'\n\t' (no space). Unquoted `--lang "$RW_LANG"` would become one argv
  # `--lang ru` and 1.4.0 then treated it as an unknown command after restart.
  if [[ -n "${RW_LANG:-}" ]]; then
    exec bash "$dest" --lang "$RW_LANG" --no-update-check
  fi
  exec bash "$dest" --no-update-check
}

# 25.x-prod is epoch 0; 1.x+ is epoch 1 so sort -V does not treat 25.2.7 as newer than 1.3.0.
normalize_tag(){
  local v="${1:-}"
  v="${v#v}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

version_epoch(){
  local v; v="$(normalize_tag "$1")"
  case "$v" in
    *-prod|25.*) printf 0 ;;
    *) printf 1 ;;
  esac
}

version_core(){
  local v; v="$(normalize_tag "$1")"
  v="${v%-prod}"
  printf '%s' "$v"
}

version_is_newer(){
  local remote localv er el cr cl
  remote="$(normalize_tag "${1:-}")"
  localv="$(normalize_tag "${2:-}")"
  [[ -n "$remote" && -n "$localv" ]] || return 1
  [[ "$remote" == "$localv" ]] && return 1
  er="$(version_epoch "$remote")"
  el="$(version_epoch "$localv")"
  [[ "$er" -gt "$el" ]] && return 0
  [[ "$er" -lt "$el" ]] && return 1
  cr="$(version_core "$remote")"
  cl="$(version_core "$localv")"
  [[ "$cr" == "$cl" ]] && return 1
  [[ "$(printf '%s\n' "$cl" "$cr" | sort -V | tail -1)" == "$cr" ]]
}

fetch_latest_tag(){
  local json tag loc atom snippet
  json="$(curl -fsS --connect-timeout 10 --max-time 25 --retry 2 --retry-all-errors \
    -H 'Accept: application/vnd.github+json' \
    -A 'remnawave-manager' \
    "${GITHUB_LATEST_API}" 2>/dev/null || true)"
  tag="$(printf '%s' "$json" | jq -r '.tag_name // empty' 2>/dev/null || true)"
  tag="$(normalize_tag "$tag")"
  if [[ -n "$tag" && "$tag" != null ]]; then
    printf '%s' "$tag"
    return 0
  fi
  # Do not follow -L to release-assets.githubusercontent.com: that URL has no tag.
  loc="$(http_first_redirect "$GITHUB_LATEST_HTML")"
  tag="$(tag_from_github_url "$loc")"
  if [[ -n "$tag" && "$tag" != null ]]; then
    printf '%s' "$tag"
    return 0
  fi
  loc="$(http_first_redirect "$SELF_UPDATE_URL")"
  tag="$(tag_from_github_url "$loc")"
  if [[ -n "$tag" && "$tag" != null ]]; then
    printf '%s' "$tag"
    return 0
  fi
  atom="$(curl -fsS --connect-timeout 10 --max-time 25 --retry 2 --retry-all-errors \
    -A 'remnawave-manager' "$GITHUB_RELEASES_ATOM" 2>/dev/null || true)"
  tag="$(printf '%s' "$atom" | sed -n 's#.*releases/tag/\([^<"'\''[:space:]]*\).*#\1#p')"
  tag="${tag%%$'\n'*}"
  tag="$(normalize_tag "$tag")"
  if [[ -n "$tag" && "$tag" != null ]]; then
    printf '%s' "$tag"
    return 0
  fi
  snippet="$(curl -fsSL --connect-timeout 10 --max-time 25 --retry 2 --retry-all-errors \
    -A 'remnawave-manager' -r 0-8191 "$JSDELIVR_LATEST_URL" 2>/dev/null || true)"
  tag="$(printf '%s' "$snippet" | sed -n "s/^VERSION='\\([^']*\\)'.*/\\1/p")"
  tag="${tag%%$'\n'*}"
  tag="$(normalize_tag "$tag")"
  [[ -n "$tag" && "$tag" != null ]] || return 1
  printf '%s' "$tag"
}

persist_update_check(){
  persist_manager LAST_UPDATE_CHECK_AT "${LAST_UPDATE_CHECK_AT:-}" 2>/dev/null || true
  persist_manager LAST_REMOTE_VERSION "${REMOTE_VERSION:-}" 2>/dev/null || true
}

refresh_update_available(){
  UPDATE_AVAILABLE=0
  [[ -n "${REMOTE_VERSION:-}" ]] || return 1
  if version_is_newer "$REMOTE_VERSION" "$VERSION"; then
    UPDATE_AVAILABLE=1
    return 0
  fi
  return 1
}

# Returns 0 when a newer GitHub Latest exists. Network errors return 1 without aborting.
check_self_update(){
  local force="${1:-0}" now last age tag
  [[ ${SKIP_UPDATE_CHECK:-0} -eq 1 ]] && return 1
  [[ ${DRY_RUN:-0} -eq 1 ]] && return 1
  now="$(date +%s)"
  last="${LAST_UPDATE_CHECK_AT:-0}"
  [[ "$last" =~ ^[0-9]+$ ]] || last=0
  age=$((now - last))
  # TTL cache for any last tag (current or newer). Menu 26 / check-update pass force=1.
  if [[ "$force" != 1 && "$age" -ge 0 && "$age" -lt ${UPDATE_CHECK_TTL:-21600} \
     && -n "${LAST_REMOTE_VERSION:-}" ]]; then
    REMOTE_VERSION="$LAST_REMOTE_VERSION"
  else
    tag="$(fetch_latest_tag || true)"
    if [[ -n "$tag" ]]; then
      REMOTE_VERSION="$tag"
      LAST_UPDATE_CHECK_AT="$now"
      LAST_REMOTE_VERSION="$tag"
      persist_update_check
    elif [[ -n "${LAST_REMOTE_VERSION:-}" ]]; then
      REMOTE_VERSION="$LAST_REMOTE_VERSION"
      warn "$(t upd_cached "$REMOTE_VERSION")"
    else
      return 1
    fi
  fi
  refresh_update_available
}

maybe_prompt_self_update(){
  check_self_update || true
  [[ ${UPDATE_AVAILABLE:-0} -eq 1 ]] || return 0
  [[ ${UPDATE_PROMPT_DONE:-0} -eq 1 ]] && return 0
  UPDATE_PROMPT_DONE=1
  echo
  echo "${U_YELLOW}${U_BOLD}$(t upd_available "$REMOTE_VERSION" "$VERSION")${U_RESET}"
  [[ ${AUTO_YES:-0} -eq 1 ]] && return 0
  local ans
  read -r -p "$(t upd_prompt)" ans || true
  ans="${ans:-Y}"
  case "$ans" in
    y|Y|yes|YES|да|Да|ДА)
      require_root
      self_update
      ;;
    *) echo "$(t upd_skip)" ;;
  esac
}

check_update_cli(){
  local apply=0
  case "${1:-}" in
    --apply|apply) apply=1 ;;
  esac
  if check_self_update 1; then
    echo "$(t upd_available "$REMOTE_VERSION" "$VERSION")"
    if [[ $apply -eq 1 ]]; then
      require_root
      self_update
    fi
    return 0
  fi
  if [[ -n "${REMOTE_VERSION:-}" ]]; then
    echo "$(t upd_current "$VERSION")"
    return 0
  fi
  warn "$(t upd_fail)"
  return 1
}

community_update_menu(){
  local choice
  echo
  echo "${U_BLUE}${U_BOLD}$(t comm_title)${U_RESET}"
  echo "${U_SKY}$(t comm_keep)${U_RESET}"
  echo "$(t comm_1)"
  echo "$(t comm_2)"
  echo "$(t comm_3)"
  echo "$(t comm_0)"
  read -r -p "$(t prompt_choice)" choice
  case "$choice" in
    1) require_root; refresh_community_modules ;;
    2) require_root; self_update ;;
    3) check_update_cli || true ;;
    0|'') return 0 ;;
    *) echo "$(t err_unknown_item)" ;;
  esac
}

install_single(){
  local node_addr
  preflight single
  install_base; configure_security; configure_kernel
  check_dns "$DOMAIN_PANEL"; check_dns "$DOMAIN_SUB"; check_dns "$DOMAIN_REALITY"
  MODE=single write_panel_env
  install_panel_compose; wait_api
  bootstrap_auth; create_subscription_token; get_node_secret; generate_x25519
  create_config_profile
  write_node_compose "$BASE/node" "$NODE_SECRET_KEY"
  configure_node_logs "$BASE/node"
  node_addr="$(node_host_address)"
  log "Адрес Node для панели: $node_addr (не 127.0.0.1 — панель работает в Docker)."
  create_node "$node_addr" "$BRAND"
  bind_all
  setup_panel_web
  install_selfsteal
  install_telegram_alerts
  install_subscription
  wait_subscription || warn "$(t wait_sub_fail)"
  rezzosoft_prepare_node || warn 'Rezzosoft: порты/certs не критичны.'
  [[ $HYSTERIA2 -eq 1 ]] && install_hysteria2
  [[ "${XCORE_SOURCE:-builtin}" != builtin ]] && install_xray_core "$BASE/node" "$XCORE_SOURCE"
  [[ $MONITORING -eq 1 ]] && install_monitoring
  write_firewall single
  configure_admin_ip
  configure_remote_backup
  write_bootstrap; finish_config; write_credentials; install_timers
  ok "$(t single_ok)"
  show_result
}

install_panel(){
  preflight panel
  install_base; configure_security; configure_kernel
  check_dns "$DOMAIN_PANEL"; check_dns "$DOMAIN_SUB"
  MODE=panel write_panel_env
  install_panel_compose; wait_api
  bootstrap_auth; create_subscription_token; generate_x25519; create_config_profile
  if [[ -n "${EDGE_ADDRESS:-}" ]]; then
    get_node_secret
    create_node "$EDGE_ADDRESS" "${BRAND}-EDGE"
  fi
  bind_all
  write_http_server "$DOMAIN_PANEL" "$DOMAIN_SUB"
  issue_cert "$DOMAIN_PANEL" "$ADMIN_EMAIL"; issue_cert "$DOMAIN_SUB" "$ADMIN_EMAIL"
  cat > /etc/nginx/conf.d/rate-limit.conf <<'EOF2'
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=30r/s;
EOF2
  tls_params; set_gzip; write_panel_vhosts
  write_sni_router 0
  install_subscription
  wait_subscription || warn "$(t wait_sub_fail)"
  write_firewall panel; configure_admin_ip; configure_remote_backup; write_bootstrap; finish_config; write_credentials; install_timers
  [[ $MONITORING -eq 1 ]] && install_monitoring
  install_telegram_alerts
  ok "$(t panel_ok)"; show_result
}

install_edge(){
  preflight edge
  install_base; configure_security; configure_kernel
  check_dns "$DOMAIN_REALITY"
  mkdir -p "$EDGE_BASE"
  cat > "$EDGE_ENV" <<EOF2
MODE=edge
PANEL_IP=$PANEL_IP
DOMAIN_NODE=$DOMAIN_NODE
DOMAIN_REALITY=$DOMAIN_REALITY
NODE_SECRET_KEY=$NODE_SECRET_KEY
HYSTERIA2=${HYSTERIA2:-0}
ENABLE_GRPC=${ENABLE_GRPC:-0}
ENABLE_XHTTP=${ENABLE_XHTTP:-0}
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
  listen 127.0.0.1:9450 ssl http2;
  server_name ${DOMAIN_REALITY};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_REALITY}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_REALITY}/privkey.pem;
  include /etc/nginx/snippets/remnawave-ssl.conf;
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
  write_reject_vhost '127.0.0.1:9444'
  grep -Fq "include $STREAM_CONF;" /etc/nginx/nginx.conf || sed -i "/^http {/i include $STREAM_CONF;" /etc/nginx/nginx.conf
  nginx -t >/dev/null && systemctl reload nginx
  write_firewall edge; configure_admin_ip; install_timers
  persist_protocol_flags
  rezzosoft_prepare_node
  ok "$(t edge_ok)"
}

check_dns(){
  local d="$1" ip answers
  answers="$(getent ahostsv4 "$d" | awk '{print $1}' | sort -u || true)"
  [[ -n "$answers" ]] || die "DNS A-запись для $d отсутствует."
  ip="$(public_ip)"
  if [[ -n "$ip" && ! " $answers " =~ [[:space:]]$ip[[:space:]] ]]; then warn "DNS $d не совпадает с публичным IP $ip. Если это намеренно, установка продолжится."; else ok "DNS $d: $answers"; fi
}

port_is_bound(){
  local proto="$1" port="$2"
  if [[ "$proto" == udp ]]; then
    ss -H -lun "( sport = :${port} )" 2>/dev/null | grep -q .
  else
    ss -H -ltn "( sport = :${port} )" 2>/dev/null | grep -q .
  fi
}

cert_days_left(){
  local pem="$1" end now
  [[ -r "$pem" ]] || return 1
  end="$(openssl x509 -enddate -noout -in "$pem" 2>/dev/null | cut -d= -f2- || true)"
  [[ -n "$end" ]] || return 1
  end="$(date -d "$end" +%s 2>/dev/null || true)"
  now="$(date +%s)"
  [[ -n "$end" && "$end" =~ ^[0-9]+$ ]] || return 1
  echo $(( (end - now) / 86400 ))
}

preflight(){
  local mode="${1:-${MODE:-single}}" kb freeh
  echo "${U_BLUE}${U_BOLD}$(t pf_title)${U_RESET}"
  check_os
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    log "[DRY-RUN] $(t pf_title) mode=$mode"
    ok "$(t pf_ok)"
    return 0
  fi
  case "$mode" in
    panel)
      [[ -n "${DOMAIN_PANEL:-}" ]] && check_dns "$DOMAIN_PANEL"
      [[ -n "${DOMAIN_SUB:-}" ]] && check_dns "$DOMAIN_SUB"
      [[ -n "${DOMAIN_REALITY:-}" ]] && check_dns "$DOMAIN_REALITY" || true
      ;;
    edge|node)
      [[ -n "${DOMAIN_REALITY:-}" ]] && check_dns "$DOMAIN_REALITY"
      ;;
    *)
      [[ -n "${DOMAIN_PANEL:-}" ]] && check_dns "$DOMAIN_PANEL"
      [[ -n "${DOMAIN_SUB:-}" ]] && check_dns "$DOMAIN_SUB"
      [[ -n "${DOMAIN_REALITY:-}" ]] && check_dns "$DOMAIN_REALITY"
      ;;
  esac
  if already_installed; then
    ok "$(t pf_port_ok 80 tcp) (nginx)"
    ok "$(t pf_port_ok 443 tcp) (nginx)"
  else
    if port_is_bound tcp 80; then die "$(t pf_port_busy 80 tcp)"; else ok "$(t pf_port_ok 80 tcp)"; fi
    if port_is_bound tcp 443; then die "$(t pf_port_busy 443 tcp)"; else ok "$(t pf_port_ok 443 tcp)"; fi
  fi
  kb="$(df -Pk / 2>/dev/null | awk 'NR==2{print $4}')"
  freeh="$(df -h / 2>/dev/null | awk 'NR==2{print $4}')"
  [[ "${kb:-0}" =~ ^[0-9]+$ ]] || kb=0
  if [[ "$kb" -gt 0 && "$kb" -lt 4194304 ]]; then
    warn "$(t pf_disk_low 4 "${freeh:-?}")"
  else
    ok "$(t pf_disk_ok "${freeh:-?}")"
  fi
  if command -v docker >/dev/null 2>&1; then
    ok "$(t pf_docker_ok "$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo ok)")"
  else
    ok "$(t pf_docker_miss)"
  fi
  ok "$(t pf_ok)"
}

print_version(){
  printf 'remnawave-manager %s\n' "$VERSION"
}

say_tty(){
  printf '%s\n' "$*"
}

require_panel_api(){
  detect_install_mode
  [[ "${MODE:-single}" != edge ]] || die "$(t err_need_panel)"
  already_installed || [[ -f "$BASE/docker-compose.yml" ]] || die "$(t err_repair_no_install)"
  bootstrap_auth
}

print_node_apply_hint(){
  [[ "${MODE:-single}" == panel ]] || return 0
  echo
  echo "${U_YELLOW}${U_BOLD}$(t nt_next_title)${U_RESET}"
  if [[ -n "${TARGET_NODE_UUID:-}" ]]; then
    echo "$(t nt_next_one "$TARGET_NODE_UUID")"
  else
    echo "$(t nt_next_all)"
  fi
  echo "$(t nt_next_cmd)"
}

cert_nearest(){
  local d pem days best=9999 name=''
  for d in ${DOMAIN_PANEL:-} ${DOMAIN_SUB:-} ${DOMAIN_REALITY:-}; do
    [[ -n "$d" ]] || continue
    pem="/etc/letsencrypt/live/${d}/fullchain.pem"
    days="$(cert_days_left "$pem" 2>/dev/null || true)"
    [[ "$days" =~ ^-?[0-9]+$ ]] || continue
    if [[ "$days" -lt "$best" ]]; then
      best="$days"
      name="$d"
    fi
  done
  [[ -n "$name" ]] || return 1
  printf '%s %s' "$name" "$best"
}

print_menu_certs(){
  local pair name days
  pair="$(cert_nearest 2>/dev/null || true)"
  if [[ -z "$pair" ]]; then
    printf '  %s%s%s\n' "$U_DIM" "$(t menu_cert_na)" "$U_RESET"
    return 0
  fi
  name="${pair%% *}"
  days="${pair##* }"
  if [[ "$days" -lt 21 ]]; then
    printf '  %s%s%s\n' "$U_YELLOW$U_BOLD" "$(t menu_cert_soon "$name" "$days")" "$U_RESET"
  else
    printf '  %s%s%s\n' "$U_DIM" "$(t menu_cert "$name" "$days")" "$U_RESET"
  fi
}

users_json(){
  local raw
  raw="$(api_call GET /users/ '' "$API_JWT" 2>/dev/null || true)"
  api_json_soft "$raw" || true
}

users_tsv(){
  local json="$1"
  [[ -n "$json" ]] || return 0
  jq -r '
    def users:
      if (.response|type)=="array" then .response[]?
      elif ((.response.users // empty)|type)=="array" then .response.users[]?
      elif ((.response.users.users // empty)|type)=="array" then .response.users.users[]?
      else empty end;
    users | [(.uuid // ""), (.username // ""), (.status // ""), (.shortUuid // ""), (.subscriptionUrl // "")] | @tsv
  ' <<<"$json"
}

user_sub_url(){
  local short="$1" url="$2"
  if [[ -n "$url" && "$url" != null ]]; then
    printf '%s' "$url"
    return 0
  fi
  [[ -n "$short" ]] && printf 'https://%s/%s' "${DOMAIN_SUB:-}" "$short"
}

users_list_print(){
  local json tsv i=0 uuid name st short url
  json="$(users_json)"
  tsv="$(users_tsv "$json")"
  if [[ -z "$tsv" ]]; then
    echo "${U_DIM}$(t usr_empty)${U_RESET}"
    return 1
  fi
  while IFS=$'\t' read -r uuid name st short url; do
    [[ -n "$uuid" ]] || continue
    i=$((i + 1))
    printf '  [%s] %s  %s  %s\n' "$i" "$name" "$st" "$uuid"
  done <<<"$tsv"
  return 0
}

users_pick(){
  local json tsv choice i uuid name st short url
  local -a uuids names shorts urls
  json="$(users_json)"
  tsv="$(users_tsv "$json")"
  i=0
  while IFS=$'\t' read -r uuid name st short url; do
    [[ -n "$uuid" ]] || continue
    i=$((i + 1))
    uuids+=("$uuid")
    names+=("$name")
    shorts+=("$short")
    urls+=("$url")
    printf '  [%s] %s  %s  %s\n' "$i" "$name" "$st" "$uuid"
  done <<<"$tsv"
  if [[ "$i" -eq 0 ]]; then
    echo "${U_DIM}$(t usr_empty)${U_RESET}"
    return 1
  fi
  read -r -p "$(t usr_pick)" choice || true
  case "$choice" in
    q|Q|'') return 1 ;;
  esac
  if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#uuids[@]} ]]; then
    PICK_USER_UUID="${uuids[$((choice - 1))]}"
    PICK_USER_NAME="${names[$((choice - 1))]}"
    PICK_USER_SHORT="${shorts[$((choice - 1))]}"
    PICK_USER_URL="${urls[$((choice - 1))]}"
    return 0
  fi
  i=0
  for uuid in "${uuids[@]}"; do
    if [[ "$choice" == "$uuid" || "$choice" == "${names[$i]}" ]]; then
      PICK_USER_UUID="$uuid"
      PICK_USER_NAME="${names[$i]}"
      PICK_USER_SHORT="${shorts[$i]}"
      PICK_USER_URL="${urls[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  echo "$(t err_unknown_item)"
  return 1
}

users_create(){
  local name expire body raw code json short url
  read -r -p "$(t usr_prompt)" name || true
  [[ "$name" =~ ^[A-Za-z][A-Za-z0-9._-]{2,31}$ ]] || { echo "$(t usr_bad)"; return 1; }
  [[ -n "${SQUAD_UUID:-}" ]] || ensure_internal_squad || true
  expire="$(date -u -d '+10 years' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -v+10y +%Y-%m-%dT%H:%M:%S.000Z)"
  if [[ -n "${SQUAD_UUID:-}" ]]; then
    body="$(jq -nc --arg u "$name" --arg e "$expire" --arg s "$SQUAD_UUID" \
      '{username:$u, status:"ACTIVE", expireAt:$e, trafficLimitBytes:0, activeInternalSquads:[$s]}')"
  else
    body="$(jq -nc --arg u "$name" --arg e "$expire" \
      '{username:$u, status:"ACTIVE", expireAt:$e, trafficLimitBytes:0}')"
  fi
  raw="$(api_call POST /users/ "$body" "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  json="$(sed '$d' <<<"$raw")"
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || die "API HTTP $code"
  short="$(jq -r '.response.shortUuid // .response.user.shortUuid // empty' <<<"$json")"
  url="$(user_sub_url "$short" "$(jq -r '.response.subscriptionUrl // .response.user.subscriptionUrl // empty' <<<"$json")")"
  ok "$(t usr_created "$name" "${url:-n/a}")"
}

users_set_status(){
  local action="$1" raw code path
  users_pick || return 0
  path="/users/${PICK_USER_UUID}/actions/${action}"
  raw="$(api_call POST "$path" '{}' "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
    raw="$(api_call POST "$path" '' "$API_JWT" || true)"
    code="$(tail -n1 <<<"$raw")"
  fi
  if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
    local st='ACTIVE'
    [[ "$action" == disable ]] && st='DISABLED'
    raw="$(api_call PATCH /users/ "$(jq -nc --arg u "$PICK_USER_UUID" --arg s "$st" '{uuid:$u,status:$s}')" "$API_JWT" || true)"
    code="$(tail -n1 <<<"$raw")"
  fi
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || die "API HTTP $code"
  ok "$(t usr_status "$PICK_USER_NAME" "$action")"
}

users_show_sub(){
  local url
  users_pick || return 0
  url="$(user_sub_url "$PICK_USER_SHORT" "$PICK_USER_URL")"
  say_tty "$(t usr_sub "${url:-n/a}")"
}

users_menu(){
  local choice
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  require_panel_api
  while true; do
    echo
    echo "${U_BLUE}${U_BOLD}$(t usr_title)${U_RESET}"
    echo "$(t usr_1)"
    echo "$(t usr_2)"
    echo "$(t usr_3)"
    echo "$(t usr_4)"
    echo "$(t usr_5)"
    echo "$(t usr_0)"
    echo "$(t nt_q)"
    read -r -p "$(t prompt_choice)" choice
    case "$choice" in
      1) users_list_print || true ;;
      2) users_create ;;
      3) users_set_status enable ;;
      4) users_set_status disable ;;
      5) users_show_sub ;;
      0|'') return 0 ;;
      q|Q) return 0 ;;
      *) echo "$(t err_unknown_item)" ;;
    esac
  done
}

users_cli(){
  local act="${1:-list}" name
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  require_panel_api
  case "$act" in
    list|'') users_list_print || true ;;
    create)
      name="${2:-}"
      if [[ -z "$name" ]]; then users_create; else
        [[ "$name" =~ ^[A-Za-z][A-Za-z0-9._-]{2,31}$ ]] || die "$(t usr_bad)"
        PICK_USER_NAME="$name"
        local expire body raw code json short url
        [[ -n "${SQUAD_UUID:-}" ]] || ensure_internal_squad || true
        expire="$(date -u -d '+10 years' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -v+10y +%Y-%m-%dT%H:%M:%S.000Z)"
        body="$(jq -nc --arg u "$name" --arg e "$expire" --arg s "${SQUAD_UUID:-}" \
          'if $s=="" then {username:$u,status:"ACTIVE",expireAt:$e,trafficLimitBytes:0}
           else {username:$u,status:"ACTIVE",expireAt:$e,trafficLimitBytes:0,activeInternalSquads:[$s]} end')"
        raw="$(api_call POST /users/ "$body" "$API_JWT" || true)"
        code="$(tail -n1 <<<"$raw")"
        json="$(sed '$d' <<<"$raw")"
        [[ "$code" =~ ^2[0-9][0-9]$ ]] || die "API HTTP $code"
        short="$(jq -r '.response.shortUuid // .response.user.shortUuid // empty' <<<"$json")"
        url="$(user_sub_url "$short" "$(jq -r '.response.subscriptionUrl // .response.user.subscriptionUrl // empty' <<<"$json")")"
        ok "$(t usr_created "$name" "${url:-n/a}")"
      fi
      ;;
    enable|disable)
      PICK_USER_UUID="${2:-}"
      PICK_USER_NAME="${2:-}"
      [[ -n "$PICK_USER_UUID" ]] || die "$(t usr_pick)"
      if [[ ! "$PICK_USER_UUID" =~ ^[0-9a-fA-F-]{32,36}$ ]]; then
        local json tsv uuid uname st short url
        json="$(users_json)"
        tsv="$(users_tsv "$json")"
        uname="$PICK_USER_UUID"
        PICK_USER_UUID=''
        while IFS=$'\t' read -r uuid name st short url; do
          [[ "$name" == "$uname" ]] && { PICK_USER_UUID="$uuid"; PICK_USER_NAME="$name"; break; }
        done <<<"$tsv"
        [[ -n "$PICK_USER_UUID" ]] || die "$(t err_unknown_item)"
      fi
      local path raw code
      path="/users/${PICK_USER_UUID}/actions/${act}"
      raw="$(api_call POST "$path" '{}' "$API_JWT" || true)"
      code="$(tail -n1 <<<"$raw")"
      if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
        raw="$(api_call POST "$path" '' "$API_JWT" || true)"
        code="$(tail -n1 <<<"$raw")"
      fi
      if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
        local st='ACTIVE'
        [[ "$act" == disable ]] && st='DISABLED'
        raw="$(api_call PATCH /users/ "$(jq -nc --arg u "$PICK_USER_UUID" --arg s "$st" '{uuid:$u,status:$s}')" "$API_JWT" || true)"
        code="$(tail -n1 <<<"$raw")"
      fi
      [[ "$code" =~ ^2[0-9][0-9]$ ]] || die "API HTTP $code"
      ok "$(t usr_status "$PICK_USER_NAME" "$act")"
      ;;
    sub|url)
      PICK_USER_UUID="${2:-}"
      [[ -n "$PICK_USER_UUID" ]] || die "$(t usr_pick)"
      local json tsv uuid name st short url
      json="$(users_json)"
      tsv="$(users_tsv "$json")"
      while IFS=$'\t' read -r uuid name st short url; do
        if [[ "$uuid" == "$PICK_USER_UUID" || "$name" == "$PICK_USER_UUID" ]]; then
          say_tty "$(t usr_sub "$(user_sub_url "$short" "$url")")"
          return 0
        fi
      done <<<"$tsv"
      die "$(t err_unknown_item)"
      ;;
    *) die "$(t err_unknown_item)" ;;
  esac
}

nodes_tsv(){
  local tok existing
  tok="${API_JWT:-${API_TOKEN:-}}"
  existing=''
  if [[ -n "$tok" ]]; then
    existing="$(api_json_soft "$(api_call GET /nodes/ '' "$tok" 2>/dev/null || true)" || true)"
  fi
  [[ -n "$existing" ]] || return 0
  jq -r '
    def nodes:
      if (.response|type)=="array" then .response[]?
      elif ((.response.nodes // empty)|type)=="array" then .response.nodes[]?
      else empty end;
    nodes | [(.uuid // ""), (.name // "node"), (.address // ""), ((.isConnected // .isconnected // false)|tostring), ((.isDisabled // .isdisabled // false)|tostring)] | @tsv
  ' <<<"$existing"
}

nodes_list_print(){
  local uuid name addr conn dis st
  local i=0
  while IFS=$'\t' read -r uuid name addr conn dis; do
    [[ -n "$uuid" ]] || continue
    i=$((i + 1))
    if [[ "$dis" == true || "$dis" == 1 ]]; then
      st='disabled'
    elif [[ "$conn" == true || "$conn" == 1 ]]; then
      st="$(t doc_connected)"
    else
      st="$(t doc_disconnected)"
    fi
    printf '  [%s] %s  %s  %s  %s\n' "$i" "$name" "$addr" "$st" "$uuid"
  done < <(nodes_tsv)
  [[ "$i" -gt 0 ]] || echo "${U_DIM}$(t nt_pick_none)${U_RESET}"
}

node_api_action(){
  local uuid="$1" action="$2" raw code
  raw="$(api_call POST "/nodes/${uuid}/actions/${action}" '{}' "$API_JWT" || true)"
  code="$(tail -n1 <<<"$raw")"
  if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
    raw="$(api_call POST "/nodes/${uuid}/actions/${action}" '' "$API_JWT" || true)"
    code="$(tail -n1 <<<"$raw")"
  fi
  if [[ ! "$code" =~ ^2[0-9][0-9]$ && "$action" == restart ]]; then
    raw="$(api_call POST "/nodes/${uuid}/actions/restart" '{"forceRestart":true}' "$API_JWT" || true)"
    code="$(tail -n1 <<<"$raw")"
  fi
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || die "API HTTP $code"
}

node_control_run(){
  local action="$1" addr="${2:-}" uuid="${3:-}"
  if [[ -z "$uuid" ]]; then
    TARGET_NODE_UUID=''
    pick_target_node || return 0
    uuid="${TARGET_NODE_UUID:-}"
  fi
  if [[ "$action" != restart && -z "$uuid" ]]; then
    echo "$(t nctl_need)"
    return 1
  fi
  if [[ "$action" == restart && -z "$uuid" ]]; then
    restart_all_nodes
    return 0
  fi
  case "$action" in
    restart)
      node_api_action "$uuid" restart
      ok "$(t nctl_restarted "$uuid")"
      ;;
    disable|enable)
      node_api_action "$uuid" "$action"
      ok "$(t nctl_ok "$uuid" "$action")"
      ;;
    address)
      if [[ -z "$addr" ]]; then
        read -r -p "$(t nctl_addr)" addr || true
      fi
      [[ -n "$addr" ]] || return 1
      if ! validate_ip "$addr" && ! validate_domain "$addr"; then
        die "$(t err_invalid address "$addr")"
      fi
      api_json "$(api_call PATCH /nodes/ "$(jq -nc --arg u "$uuid" --arg a "$addr" '{uuid:$u,address:$a}')" "$API_JWT")" >/dev/null
      ok "$(t nctl_addr_ok "$uuid" "$addr")"
      ;;
  esac
}

node_control_menu(){
  local choice
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  require_panel_api
  while true; do
    echo
    echo "${U_BLUE}${U_BOLD}$(t nctl_title)${U_RESET}"
    echo "$(t nctl_1)"
    echo "$(t nctl_2)"
    echo "$(t nctl_3)"
    echo "$(t nctl_4)"
    echo "$(t nctl_5)"
    echo "$(t nctl_0)"
    echo "$(t nt_q)"
    read -r -p "$(t prompt_choice)" choice
    case "$choice" in
      1) nodes_list_print ;;
      2) node_control_run restart ;;
      3) node_control_run disable ;;
      4) node_control_run enable ;;
      5) node_control_run address ;;
      0|'') return 0 ;;
      q|Q) return 0 ;;
      *) echo "$(t err_unknown_item)" ;;
    esac
  done
}

node_control_cli(){
  local act="${1:-list}" extra="${2:-}"
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  require_panel_api
  case "$act" in
    list|'') nodes_list_print ;;
    restart)
      if [[ "$extra" == all || "$extra" == 0 || -z "$extra" ]]; then
        if [[ -z "$extra" && ${AUTO_YES:-0} -eq 0 ]]; then
          node_control_run restart
        else
          restart_all_nodes
        fi
      else
        TARGET_NODE_UUID="$extra"
        node_api_action "$extra" restart
        ok "$(t nctl_restarted "$extra")"
      fi
      ;;
    disable|enable)
      extra="${extra:-}"
      [[ -n "$extra" ]] || { node_control_run "$act"; return 0; }
      node_api_action "$extra" "$act"
      ok "$(t nctl_ok "$extra" "$act")"
      ;;
    address)
      local uuid="$extra" addr="${3:-}"
      [[ -n "$uuid" ]] || { node_control_run address; return 0; }
      node_control_run address "$addr" "$uuid"
      ;;
    *) die "$(t err_unknown_item)" ;;
  esac
}

tg_mask(){
  local s="${1:-}"
  [[ ${#s} -gt 4 ]] || { printf '****'; return 0; }
  printf '…%s' "${s: -4}"
}

telegram_post(){
  local text="$1"
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]] || return 1
  local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
  local args=(--data-urlencode "chat_id=$TELEGRAM_CHAT_ID" --data-urlencode "text=$text")
  [[ -n "${TELEGRAM_THREAD_ID:-}" ]] && args+=(--data-urlencode "message_thread_id=$TELEGRAM_THREAD_ID")
  curl -fsS --max-time 15 -X POST "$url" "${args[@]}" >/dev/null 2>&1
}

write_health_notify_script(){
  mkdir -p /usr/local/sbin /var/lib/remnawave
  cat > /usr/local/sbin/remnawave-health-notify.sh <<'EOF2'
#!/usr/bin/env bash
set -u
envf=/opt/remnawave/manager.env
[[ -r "$envf" ]] || exit 0
kv(){ awk -F= -v k="$1" '$1==k{print substr($0,index($0,"=")+1); exit}' "$envf"; }
alerts="$(kv TELEGRAM_ALERTS)"
[[ "$alerts" == 1 ]] || exit 0
token="$(kv TELEGRAM_BOT_TOKEN)"
chat="$(kv TELEGRAM_CHAT_ID)"
thread="$(kv TELEGRAM_THREAD_ID)"
[[ -n "$token" && -n "$chat" ]] || exit 0
stampdir=/var/lib/remnawave
mkdir -p "$stampdir"
send(){
  local key="$1" msg="$2" now last
  now="$(date +%s)"
  last="$(cat "$stampdir/tg-$key" 2>/dev/null || echo 0)"
  if [[ "$last" =~ ^[0-9]+$ ]] && (( now - last < 3600 )); then return 0; fi
  local args=(--data-urlencode "chat_id=$chat" --data-urlencode "text=$msg")
  [[ -n "$thread" ]] && args+=(--data-urlencode "message_thread_id=$thread")
  if curl -fsS --max-time 15 -X POST "https://api.telegram.org/bot${token}/sendMessage" "${args[@]}" >/dev/null 2>&1; then
    echo "$now" > "$stampdir/tg-$key"
  fi
}
panel="$(kv DOMAIN_PANEL)"
sub="$(kv DOMAIN_SUB)"
reality="$(kv DOMAIN_REALITY)"
api_tok="$(kv API_TOKEN)"
host="${panel:-localhost}"
if ! curl -fsS --max-time 5 \
  -H 'X-Forwarded-For: 127.0.0.1' -H 'X-Forwarded-Proto: https' \
  -H "X-Forwarded-Host: ${host}" -H "Host: ${host}" \
  http://127.0.0.1:3000/api/auth/status >/dev/null 2>&1; then
  send panel "Remnawave: panel API down on $(hostname)"
fi
for d in $panel $sub $reality; do
  [[ -n "$d" ]] || continue
  pem="/etc/letsencrypt/live/${d}/fullchain.pem"
  [[ -r "$pem" ]] || continue
  end="$(openssl x509 -enddate -noout -in "$pem" 2>/dev/null | cut -d= -f2- || true)"
  end_s="$(date -d "$end" +%s 2>/dev/null || echo 0)"
  now="$(date +%s)"
  days=$(( (end_s - now) / 86400 ))
  if [[ "$days" -lt 21 ]]; then
    send "cert-$d" "Remnawave: certificate $d expires in ${days} days"
  fi
done
if [[ -n "$api_tok" ]]; then
  raw="$(curl -sS --max-time 15 -H "Authorization: Bearer ${api_tok}" \
    -H 'Accept: application/json' -H 'X-Forwarded-For: 127.0.0.1' \
    -H 'X-Forwarded-Proto: https' -H "Host: ${host}" \
    http://127.0.0.1:3000/api/nodes/ 2>/dev/null || true)"
  echo "$raw" | jq -r '
    def nodes:
      if (.response|type)=="array" then .response[]?
      elif ((.response.nodes // empty)|type)=="array" then .response.nodes[]?
      else empty end;
    nodes | select((.isDisabled // false) != true) |
      [(.uuid // ""), (.name // "node"), ((.isConnected // .isconnected // false)|tostring)] | @tsv
  ' 2>/dev/null | while IFS=$'\t' read -r uuid name conn; do
    [[ -n "$uuid" ]] || continue
    if [[ "$conn" != true && "$conn" != 1 ]]; then
      send "node-$uuid" "Remnawave: node $name is not Connected"
    fi
  done
fi
EOF2
  chmod 700 /usr/local/sbin/remnawave-health-notify.sh
}

ensure_health_notify_hook(){
  local hc=/usr/local/sbin/remnawave-healthcheck.sh
  [[ -f "$hc" ]] || return 0
  if ! grep -Fq remnawave-health-notify.sh "$hc"; then
    printf '\nif [[ -x /usr/local/sbin/remnawave-health-notify.sh ]]; then\n  /usr/local/sbin/remnawave-health-notify.sh || true\nfi\n' >> "$hc"
  fi
}

telegram_enable_interactive(){
  local token chat thread
  read -r -p "$(t alb_token)" token || true
  read -r -p "$(t alb_chat)" chat || true
  read -r -p "$(t alb_thread)" thread || true
  [[ -n "$token" && -n "$chat" ]] || die "$(t alb_test_fail)"
  TELEGRAM_BOT_TOKEN="$token"
  TELEGRAM_CHAT_ID="$chat"
  TELEGRAM_THREAD_ID="$thread"
  TELEGRAM_ALERTS=1
  persist_manager TELEGRAM_BOT_TOKEN "$TELEGRAM_BOT_TOKEN"
  persist_manager TELEGRAM_CHAT_ID "$TELEGRAM_CHAT_ID"
  persist_manager TELEGRAM_THREAD_ID "${TELEGRAM_THREAD_ID:-}"
  persist_manager TELEGRAM_ALERTS 1
  write_health_notify_script
  ensure_health_notify_hook
  if telegram_post "Remnawave Manager $VERSION: Telegram alerts enabled on $(hostname)"; then
    ok "$(t alb_test_ok)"
  else
    warn "$(t alb_test_fail)"
  fi
}

telegram_test_now(){
  HYDRATE_QUIET=1 hydrate_install_state
  [[ "${TELEGRAM_ALERTS:-0}" == 1 ]] || TELEGRAM_ALERTS=1
  if telegram_post "Remnawave Manager $VERSION test from $(hostname)"; then
    ok "$(t alb_test_ok)"
  else
    warn "$(t alb_test_fail)"
  fi
}

telegram_disable_now(){
  persist_manager TELEGRAM_ALERTS 0
  TELEGRAM_ALERTS=0
  ok "$(t alb_off)"
}

backup_remote_enable(){
  local dest="${1:-}"
  if [[ -z "$dest" ]]; then
    read -r -p "$(t alb_remote)" dest || true
  fi
  [[ -n "$dest" ]] || return 1
  BACKUP_REMOTE="$dest"
  persist_manager BACKUP_REMOTE "$BACKUP_REMOTE"
  configure_remote_backup
  ok "$(t alb_remote_ok "$BACKUP_REMOTE")"
}

backup_remote_run_now(){
  HYDRATE_QUIET=1 hydrate_install_state
  [[ -n "${BACKUP_REMOTE:-}" ]] || die "$(t alb_need_remote)"
  configure_remote_backup
  /usr/local/sbin/remnawave-remote-backup.sh
  ok "$(t alb_remote_run)"
}

backup_remote_disable(){
  systemctl disable --now remnawave-remote-backup.timer >/dev/null 2>&1 || true
  persist_manager BACKUP_REMOTE ""
  BACKUP_REMOTE=''
  ok "$(t alb_remote_off)"
}

alerts_backup_menu(){
  local choice masked chat
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  while true; do
    echo
    echo "${U_BLUE}${U_BOLD}$(t alb_title)${U_RESET}"
    if [[ "${TELEGRAM_ALERTS:-0}" == 1 && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
      masked="$(tg_mask "${TELEGRAM_BOT_TOKEN:-}")"
      echo "$(t alb_tg "$(t alb_on) ($masked)" "$TELEGRAM_CHAT_ID")"
    else
      echo "$(t alb_tg_off)"
    fi
    if [[ -n "${BACKUP_REMOTE:-}" ]]; then
      echo "  rclone: $BACKUP_REMOTE"
    fi
    echo "$(t alb_1)"
    echo "$(t alb_2)"
    echo "$(t alb_3)"
    echo "$(t alb_4)"
    echo "$(t alb_5)"
    echo "$(t alb_6)"
    echo "$(t alb_0)"
    echo "$(t nt_q)"
    read -r -p "$(t prompt_choice)" choice
    case "$choice" in
      1) telegram_enable_interactive ;;
      2) telegram_test_now ;;
      3) telegram_disable_now ;;
      4) backup_remote_enable ;;
      5) backup_remote_run_now ;;
      6) backup_remote_disable ;;
      0|'') return 0 ;;
      q|Q) return 0 ;;
      *) echo "$(t err_unknown_item)" ;;
    esac
  done
}

certs_show(){
  local d pem days
  echo
  echo "${U_BLUE}${U_BOLD}$(t crt_title)${U_RESET}"
  for d in ${DOMAIN_PANEL:-} ${DOMAIN_SUB:-} ${DOMAIN_REALITY:-}; do
    [[ -n "$d" ]] || continue
    pem="/etc/letsencrypt/live/${d}/fullchain.pem"
    if days="$(cert_days_left "$pem")"; then
      if [[ "$days" -lt 21 ]]; then
        warn "$(t doc_cert_soon "$d" "$days")"
      else
        ok "$(t doc_cert_ok "$d" "$days")"
      fi
    else
      warn "$(t doc_cert_gone "$d")"
    fi
  done
}

certs_renew_now(){
  certbot renew --non-interactive --deploy-hook /usr/local/sbin/remnawave-nginx-reload.sh
  if [[ -x /usr/local/sbin/remnawave-nginx-reload.sh ]]; then
    /usr/local/sbin/remnawave-nginx-reload.sh || true
  else
    nginx -t >/dev/null 2>&1 && systemctl reload nginx || true
  fi
  ok "$(t crt_renew_ok)"
}

certs_force_renew(){
  local d email
  email="${ADMIN_EMAIL:-admin@${DOMAIN_PANEL:-localhost}}"
  for d in ${DOMAIN_PANEL:-} ${DOMAIN_SUB:-} ${DOMAIN_REALITY:-}; do
    [[ -n "$d" ]] || continue
    if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
      certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
        --non-interactive --agree-tos --email "$email" --key-type ecdsa --force-renewal -d "$d"
    else
      mkdir -p /var/www/html/.well-known/acme-challenge
      certbot certonly --webroot -w /var/www/html --non-interactive --agree-tos --email "$email" --key-type ecdsa --force-renewal -d "$d"
    fi
    ok "$(t crt_force_ok "$d")"
  done
  if [[ -x /usr/local/sbin/remnawave-nginx-reload.sh ]]; then
    /usr/local/sbin/remnawave-nginx-reload.sh || true
  else
    nginx -t >/dev/null 2>&1 && systemctl reload nginx || true
  fi
}

certs_menu(){
  local choice
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  while true; do
    echo
    echo "${U_BLUE}${U_BOLD}$(t crt_title)${U_RESET}"
    echo "$(t crt_1)"
    echo "$(t crt_2)"
    echo "$(t crt_3)"
    echo "$(t crt_4)"
    echo "$(t crt_0)"
    echo "$(t nt_q)"
    read -r -p "$(t prompt_choice)" choice
    case "$choice" in
      1) certs_show ;;
      2) certs_renew_now ;;
      3) certs_force_renew ;;
      4) rezzosoft_sync_certs 2>/dev/null || apply_local_node_transports || true ;;
      0|'') return 0 ;;
      q|Q) return 0 ;;
      *) echo "$(t err_unknown_item)" ;;
    esac
  done
}

firewall_rebuild_now(){
  detect_install_mode
  write_firewall "${MODE:-single}"
  configure_admin_ip
  persist_manager ADMIN_IP "${ADMIN_IP:-}"
  ok "$(t fw_rebuilt)"
}

firewall_menu(){
  local choice ip
  require_root
  HYDRATE_QUIET=1 hydrate_install_state
  detect_install_mode
  while true; do
    echo
    echo "${U_BLUE}${U_BOLD}$(t fw_title)${U_RESET}"
    if [[ -n "${ADMIN_IP:-}" ]]; then
      echo "$(t fw_ip "$ADMIN_IP")"
    else
      echo "$(t fw_ip_any)"
    fi
    echo "$(t fw_1)"
    echo "$(t fw_2)"
    echo "$(t fw_3)"
    echo "$(t fw_4)"
    echo "$(t fw_0)"
    echo "$(t nt_q)"
    read -r -p "$(t prompt_choice)" choice
    case "$choice" in
      1) ufw status verbose || true ;;
      2)
        read -r -p "$(t fw_ask_ip)" ip || true
        validate_ip "$ip" || die "$(t err_invalid ADMIN_IP "$ip")"
        ADMIN_IP="$ip"
        persist_manager ADMIN_IP "$ADMIN_IP"
        firewall_rebuild_now
        ;;
      3)
        ADMIN_IP=''
        persist_manager ADMIN_IP ""
        firewall_rebuild_now
        ok "$(t fw_cleared)"
        ;;
      4) firewall_rebuild_now ;;
      0|'') return 0 ;;
      q|Q) return 0 ;;
      *) echo "$(t err_unknown_item)" ;;
    esac
  done
}

show_admin_login_once(){
  local ans="${1:-}"
  HYDRATE_QUIET=1 hydrate_install_state
  if [[ -z "${ADMIN_USERNAME:-}" || -z "${ADMIN_PASSWORD:-}" ]]; then
    echo "$(t adm_missing "$CREDS_FILE")"
    return 1
  fi
  if [[ "$ans" != SHOW ]]; then
    read -r -p "$(t adm_ask)" ans || true
  fi
  if [[ "$ans" != SHOW ]]; then
    echo "$(t adm_cancel)"
    return 0
  fi
  say_tty "$(t adm_login)"
  say_tty "$(t adm_url "${DOMAIN_PANEL:-}")"
  say_tty "$(t adm_user "$ADMIN_USERNAME")"
  say_tty "$(t adm_pass "$ADMIN_PASSWORD")"
}

urls_and_optional_admin(){
  show_urls
  echo
  show_admin_login_once || true
}

unknown_cmd(){
  local cmd="${1:-}"
  echo "$(t unknown_cmd "${cmd:-?}")" >&2
  echo "$(t unknown_cmd_hint "$0")" >&2
  echo "$(t unknown_cmd_self "$0")" >&2
  exit 2
}

pick_target_node(){
  local existing count choice i uuid name address conn st tok
  local -a uuids names
  [[ "${MODE:-single}" == edge ]] && return 0
  [[ ${AUTO_YES:-0} -eq 1 ]] && return 0
  TARGET_NODE_UUID=''
  tok="${API_JWT:-${API_TOKEN:-}}"
  existing=''
  if [[ -n "$tok" ]]; then
    existing="$(api_json_soft "$(api_call GET /nodes/ '' "$tok" 2>/dev/null || true)" || true)"
  fi
  echo
  echo "${U_BLUE}${U_BOLD}$(t nt_pick_title)${U_RESET}"
  echo "$(t nt_pick_all)"
  echo "$(t nt_q)"
  echo "${U_DIM}$(t nt_pick_uuid)${U_RESET}"
  i=0
  count=0
  if [[ -n "$existing" ]]; then
    while IFS=$'\t' read -r uuid name address conn; do
      [[ -n "$uuid" ]] || continue
      i=$((i + 1))
      count=$i
      uuids+=("$uuid")
      names+=("$name")
      if [[ "$conn" == true || "$conn" == 1 ]]; then
        st="$(t doc_connected)"
      else
        st="$(t doc_disconnected)"
      fi
      printf '  [%s] %s  %s  %s  %s\n' "$i" "$name" "$address" "$st" "$uuid"
    done < <(jq -r '
      def nodes:
        if (.response|type)=="array" then .response[]?
        elif ((.response.nodes // empty)|type)=="array" then .response.nodes[]?
        else empty end;
      nodes | [(.uuid // ""), (.name // "node"), (.address // ""), ((.isConnected // .isconnected // false)|tostring)] | @tsv
    ' <<<"$existing")
  fi
  if [[ "$count" -eq 0 ]]; then
    echo "${U_DIM}$(t nt_pick_none)${U_RESET}"
  fi
  while true; do
    read -r -p "$(t prompt_nt_node)" choice || true
    case "$choice" in
      q|Q)
        TARGET_NODE_UUID=''
        return 1
        ;;
    esac
    if [[ -z "$choice" || "$choice" == 0 ]]; then
      TARGET_NODE_UUID=''
      echo "$(t nt_selected "$(t nt_all)" all)"
      return 0
    fi
    if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#uuids[@]} ]]; then
      TARGET_NODE_UUID="${uuids[$((choice - 1))]}"
      echo "$(t nt_selected "${names[$((choice - 1))]}" "$TARGET_NODE_UUID")"
      return 0
    fi
    if [[ "$choice" =~ ^[0-9a-fA-F-]{32,36}$ ]]; then
      TARGET_NODE_UUID="$choice"
      echo "$(t nt_selected "$choice" "$choice")"
      return 0
    fi
    echo "$(t err_unknown_item)"
  done
}

add_node_menu(){
  local addr name
  require_root
  HYDRATE_QUIET=0 hydrate_install_state
  detect_install_mode
  if [[ "${MODE:-single}" == edge ]]; then
    die "$(t addn_need_panel)"
  fi
  already_installed || [[ -f "$BASE/docker-compose.yml" ]] || die "$(t err_repair_no_install)"
  echo
  echo "${U_BLUE}${U_BOLD}$(t addn_title)${U_RESET}"
  echo "${U_DIM}$(t d27)${U_RESET}"
  addr="${EDGE_ADDRESS:-}"
  name="${NODE_NAME:-}"
  ask addr "$(t addn_addr)" "${EDGE_ADDRESS:-}"
  [[ -n "$addr" ]] || die "$(t err_cancelled)"
  if validate_ip "$addr" || validate_domain "$addr"; then
    :
  else
    die "$(t err_invalid EDGE_ADDRESS "$addr")"
  fi
  ask name "$(t addn_name)" "${NODE_NAME:-${BRAND}-EDGE}"
  name="$(canonical_node_name "$name")"
  if [[ ${PROTOCOLS_EXPLICIT:-0} -eq 0 && $AUTO_YES -eq 0 ]]; then
    ask_protocols
  fi
  bootstrap_auth
  get_node_secret
  generate_x25519
  create_node "$addr" "$name"
  TARGET_NODE_UUID="${NODE_UUID:-}"
  bind_all
  prune_protocol_hosts
  persist_protocol_flags
  ok "$(t addn_ok "$name" "$addr")"
  ok "$(t addn_secret "$CREDS_FILE")"
  show_credits
}

script_update_menu(){
  local choice
  echo
  echo "${U_BLUE}${U_BOLD}$(t m26)${U_RESET}"
  echo "${U_SKY}$(t d26)${U_RESET}"
  check_self_update 1 || true
  if [[ ${UPDATE_AVAILABLE:-0} -eq 1 ]]; then
    echo "${U_YELLOW}${U_BOLD}$(t upd_available "$REMOTE_VERSION" "$VERSION")${U_RESET}"
  elif [[ -n "${REMOTE_VERSION:-}" ]]; then
    echo "$(t upd_current "$VERSION")"
  else
    echo "$(t upd_fail)"
  fi
  echo "$(t su_1)"
  echo "$(t su_2)"
  echo "$(t su_0)"
  read -r -p "$(t prompt_choice)" choice
  case "$choice" in
    1) check_update_cli || true ;;
    2) require_root; self_update ;;
    0|'') return 0 ;;
    *) echo "$(t err_unknown_item)" ;;
  esac
}

show_result(){
  cat <<EOF2

${C_GREEN}${C_BOLD}$(t done_title)${C_RESET}
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
Squad ${BRAND}:   ${SQUAD_UUID:-n/a}
User ${BRAND}:    ${AUTO_SHORT_UUID:-n/a}
User sub URL: ${SUBSCRIPTION_URL:-https://${DOMAIN_SUB}/}

$(t done_note)

$(t done_secrets)
  $CREDS_FILE
  $ENV_FILE
  $BOOTSTRAP_FILE

$(t done_delete)
EOF2
}

status(){
  echo "$(t status_title "$VERSION")"
  docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'remnawave|remnanode|hysteria|prometheus|cadvisor|node-exporter' || true
  systemctl is-active nginx fail2ban unattended-upgrades 2>/dev/null || true
  systemctl list-timers --all | grep remnawave || true
}

health_dot(){
  local code="$1"
  if [[ "$code" =~ ^[23][0-9][0-9]$ ]]; then
    printf '%s●%s %s' "$U_GREEN" "$U_RESET" "$code"
  elif [[ "$code" == '000' || -z "$code" ]]; then
    printf '%s●%s --' "$U_DIM" "$U_RESET"
  else
    printf '%s●%s %s' "$U_RED" "$U_RESET" "$code"
  fi
}

public_https_check(){
  local p s r
  echo
  echo "${U_BOLD}HTTPS${U_RESET}"
  if [[ -z "${DOMAIN_PANEL:-}" ]]; then
    echo "  $(t menu_health_na)"
    return 0
  fi
  p="$(probe_http_code "https://${DOMAIN_PANEL}/" -k)"
  s="$(probe_http_code "https://${DOMAIN_SUB}/" -k)"
  r="$(probe_http_code "https://${DOMAIN_REALITY}/" -k)"
  echo "  panel        $(health_dot "$p")  https://${DOMAIN_PANEL}"
  echo "  subscription $(health_dot "$s")  https://${DOMAIN_SUB}"
  echo "  reality SNI  $(health_dot "$r")  https://${DOMAIN_REALITY}"
  if [[ "$s" == 502 || "$s" == 000 ]]; then
    warn "$(t wait_sub_fail)"
  fi
}

show_urls(){
  echo
  echo "$(t urls_title "$CREDS_FILE")"
  echo "  Panel:        https://${DOMAIN_PANEL:-}"
  echo "  Subscription: https://${DOMAIN_SUB:-}"
  echo "  Reality SNI:  https://${DOMAIN_REALITY:-}"
  if [[ -n "${SUBSCRIPTION_URL:-}" && "$SUBSCRIPTION_URL" != n/a ]]; then
    echo "  ${BRAND} user:  $SUBSCRIPTION_URL"
  elif [[ -n "${AUTO_SHORT_UUID:-}" ]]; then
    echo "  ${BRAND} user:  https://${DOMAIN_SUB}/${AUTO_SHORT_UUID}"
  fi
  echo "  Converter:    $CONVERTER_URL"
  public_https_check
}

doctor(){
  local local3010 d pem days proto port label
  echo "Remnawave Manager $VERSION"
  echo "$(t doc_script "$VERSION")"
  check_self_update || true
  if [[ ${UPDATE_AVAILABLE:-0} -eq 1 ]]; then
    echo "$(t doc_latest_newer "${REMOTE_VERSION}")"
  elif [[ -n "${REMOTE_VERSION:-}" ]]; then
    echo "$(t doc_latest "$REMOTE_VERSION")"
  else
    echo "$(t doc_latest_na)"
  fi
  echo '[Docker]'
  echo '[Система]'; . /etc/os-release; echo "${PRETTY_NAME:-unknown}"; docker version --format '{{.Server.Version}}' 2>/dev/null || echo FAIL
  echo '[Nginx / веб-сервер]'; nginx -t 2>&1 | tail -5 || true
  echo '[API панели]'
  curl -fsS --max-time 5 \
    -H 'X-Forwarded-For: 127.0.0.1' \
    -H 'X-Forwarded-Proto: https' \
    -H "X-Forwarded-Host: ${DOMAIN_PANEL:-localhost}" \
    -H "Host: ${DOMAIN_PANEL:-localhost}" \
    "$API_LOCAL/auth/status" | jq . 2>/dev/null || echo unavailable
  echo '[Subscription page]'
  docker inspect -f '{{.Name}} {{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' remnawave-subscription-page 2>/dev/null || echo 'container missing'
  local3010="$(probe_http_code http://127.0.0.1:3010/ \
    -H 'X-Forwarded-For: 127.0.0.1' \
    -H 'X-Forwarded-Proto: https' \
    -H "Host: ${DOMAIN_SUB:-localhost}")"
  echo "3010 HTTP ${local3010}"
  public_https_check
  echo "[$(t doc_certs)]"
  for d in ${DOMAIN_PANEL:-} ${DOMAIN_SUB:-} ${DOMAIN_REALITY:-}; do
    [[ -n "$d" ]] || continue
    pem="/etc/letsencrypt/live/${d}/fullchain.pem"
    if days="$(cert_days_left "$pem")"; then
      if [[ "$days" -lt 21 ]]; then
        warn "$(t doc_cert_soon "$d" "$days")"
      else
        ok "$(t doc_cert_ok "$d" "$days")"
      fi
    else
      warn "$(t doc_cert_gone "$d")"
    fi
  done
  echo "[$(t doc_listen)]"
  doctor_listen_one(){
    local proto="$1" port="$2"
    if port_is_bound "$proto" "$port"; then
      ok "$(t doc_listen_ok "$proto" "$port")"
    else
      warn "$(t doc_listen_miss "$proto" "$port")"
    fi
  }
  doctor_listen_one tcp 80
  doctor_listen_one tcp 443
  if [[ ${HYSTERIA2:-0} -eq 1 ]]; then
    doctor_listen_one udp 443
    doctor_listen_one udp 8443
  fi
  if [[ ${ENABLE_GRPC:-0} -eq 1 ]]; then
    doctor_listen_one tcp 8443
  fi
  if [[ ${ENABLE_XHTTP:-0} -eq 1 ]]; then
    doctor_listen_one tcp 4443
  fi
  echo '[Порты]'; ss -lntup | grep -E ':(80|443|2222|3000|3001|3010|8443|8444|9443|9444|9450|4443)\b' || true
  echo "[$(t doc_nodes)]"
  if [[ "${MODE:-single}" == edge ]]; then
    echo "  $(t doc_node_na)"
  else
    local tok="${API_JWT:-${API_TOKEN:-}}" existing count
    existing=""
    if [[ -n "$tok" ]]; then
      existing="$(api_json_soft "$(api_call GET /nodes/ '' "$tok" 2>/dev/null || true)" || true)"
    fi
    count="$(jq -r '[.response[]?.uuid] | length' <<<"${existing:-}" 2>/dev/null || echo 0)"
    if [[ -z "$existing" ]]; then
      echo "  $(t doc_node_na)"
    elif [[ "${count:-0}" -eq 0 ]]; then
      echo "  $(t doc_node_none)"
    else
      while IFS=$'\t' read -r uuid name address conn; do
        [[ -n "$uuid" ]] || continue
        if [[ "$conn" == true || "$conn" == 1 ]]; then
          ok "$name  $address  $(t doc_connected)  $uuid"
        else
          warn "$name  $address  $(t doc_disconnected)  $uuid"
        fi
      done < <(jq -r '.response[]? | [(.uuid // ""), (.name // "node"), (.address // ""), ((.isConnected // .isconnected // false)|tostring)] | @tsv' <<<"$existing")
    fi
  fi
  echo '[Контейнеры]'; docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'remnawave|remnanode|hysteria|prometheus|cadvisor|node-exporter' || true
  echo '[Таймеры]'; systemctl list-timers --all | grep remnawave || true
  echo '[Firewall UFW]'; ufw status || true
}

backup(){ [[ -x /usr/local/sbin/remnawave-backup.sh ]] || die "$(t err_backup)"; /usr/local/sbin/remnawave-backup.sh; ok "$(t backup_ok "$BACKUP_BASE")"; }

update_one(){
  local d="$1"; [[ -f "$d/docker-compose.yml" ]] || return 0
  (cd "$d" && docker compose pull -q && docker compose up -d --wait --wait-timeout 180)
}
update(){
  backup
  local snap
  snap="$(find "$BACKUP_BASE" -maxdepth 1 -type f -name 'remnawave-*.tgz' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk '{print $2; exit}')"

  # Официальный порядок: Panel -> Node -> Subscription.
  if ! update_one "$BASE" || ! update_one "$BASE/node" || ! update_one "$EDGE_BASE/node" || ! update_one "$BASE/subscription" || ! update_one "$BASE/hysteria2"; then
    warn 'Обновление одного из компонентов не удалось. Возвращаем конфигурацию из последнего backup.'
    [[ -f "$snap" ]] && restore "$snap" || true
    die "$(t err_update)"
  fi
  if [[ -f "$BASE/docker-compose.yml" ]] && ! curl -fsS --max-time 8 \
    -H 'X-Forwarded-For: 127.0.0.1' \
    -H 'X-Forwarded-Proto: https' \
    -H "X-Forwarded-Host: ${DOMAIN_PANEL:-localhost}" \
    -H "Host: ${DOMAIN_PANEL:-localhost}" \
    "$API_LOCAL/auth/status" >/dev/null 2>&1; then
    warn 'Panel API не поднялся после update. Выполняю restore конфигурации.'
    [[ -f "$snap" ]] && restore "$snap" || true
    die 'Проверка панели после обновления не пройдена.'
  fi
  nginx -t && systemctl reload nginx
  ok "$(t update_ok)"
}

restore(){
  local archive="$1" tmp db_member pgpass
  [[ -f "$archive" ]] || die "$(t err_file "$archive")"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  if [[ "$archive" == *.age ]] || file "$archive" | grep -qi age; then
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
  ok "$(t restore_ok)"
}

repair(){
  log "repair: Remnawave Manager $VERSION"
  ensure_repair_domains
  [[ $DRY_RUN -eq 1 ]] && { log '[DRY-RUN] repair: nginx proxy-заголовки, vhosts, SelfSteal, subscription-page'; return 0; }
  NGINX_SKIP_RELOAD=1
  tls_params
  set_gzip
  case "${MODE:-single}" in
    panel)
      write_http_server "$DOMAIN_PANEL" "$DOMAIN_SUB"
      write_panel_vhosts
      write_sni_router 0
      ensure_subscription || warn "$(t wait_sub_fail)"
      ;;
    edge)
      install_selfsteal
      write_http_server "$DOMAIN_REALITY"
      cat > /etc/nginx/conf.d/reality-site.conf <<EOF2
server {
  listen 127.0.0.1:9450 ssl http2;
  server_name ${DOMAIN_REALITY};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN_REALITY}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_REALITY}/privkey.pem;
  include /etc/nginx/snippets/remnawave-ssl.conf;
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
      write_reject_vhost '127.0.0.1:9444'
      grep -Fq "include $STREAM_CONF;" /etc/nginx/nginx.conf || sed -i "/^http {/i include $STREAM_CONF;" /etc/nginx/nginx.conf
      ;;
    *)
      write_http_server "$DOMAIN_PANEL" "$DOMAIN_SUB" "$DOMAIN_REALITY"
      write_panel_vhosts
      write_sni_router 1
      install_selfsteal
      ensure_subscription || warn "$(t wait_sub_fail)"
      ;;
  esac
  NGINX_SKIP_RELOAD=0
  nginx_apply
  ok "$(t repair_ok)"
}

uninstall(){
  [[ $AUTO_YES -eq 1 ]] || { read -r -p "$(t prompt_uninstall)" x; [[ "$x" == DELETE ]] || die "$(t err_cancelled)"; }
  for d in "$BASE" "$BASE/subscription" "$BASE/node" "$EDGE_BASE/node" "$BASE/hysteria2" "$BASE/monitoring"; do [[ -f "$d/docker-compose.yml" ]] && (cd "$d" && docker compose down || true); done
  systemctl disable --now remnawave-healthcheck.timer remnawave-backup.timer remnawave-cert-renew.timer remnawave-remote-backup.timer remnawave-hysteria-certs.timer 2>/dev/null || true
  rm -f /etc/systemd/system/remnawave-*.service /etc/systemd/system/remnawave-*.timer /usr/local/sbin/remnawave-*.sh
  rm -f /etc/nginx/conf.d/remnawave-*.conf /etc/nginx/conf.d/00-remnawave-http.conf /etc/nginx/conf.d/reality-*.conf /etc/nginx/conf.d/ssl-params.conf /etc/nginx/conf.d/rate-limit.conf /etc/nginx/snippets/remnawave-*.conf "$STREAM_CONF"
  sed -i "/include ${STREAM_CONF//\//\\/};/d" /etc/nginx/nginx.conf 2>/dev/null || true
  systemctl daemon-reload
  nginx -t >/dev/null && systemctl reload nginx || true
  ok "$(t uninst_ok)"
}

menu_pause(){
  [[ $AUTO_YES -eq 1 ]] && return 0
  read -r -p "$(t prompt_enter)" _ || true
}

wizard(){
  local mode="$1"
  case "$mode" in
    single|panel)
      ask DOMAIN_PANEL "$(t ask_panel)" '' validate_domain
      ask DOMAIN_SUB "$(t ask_sub)" '' validate_domain
      ask DOMAIN_REALITY "$(t ask_reality)" '' validate_domain
      ask ADMIN_EMAIL "$(t ask_email)" '' validate_email
      ADMIN_USERNAME="${ADMIN_USERNAME:-${ADMIN_EMAIL%%@*}}"
      ADMIN_USERNAME="${ADMIN_USERNAME%%@*}"
      ADMIN_USERNAME="$(printf '%s' "$ADMIN_USERNAME" | tr -cd 'A-Za-z0-9._-')"
      [[ ${#ADMIN_USERNAME} -ge 3 ]] || ADMIN_USERNAME=admin
      if [[ -z "${ADMIN_PASSWORD:-}" ]]; then ADMIN_PASSWORD="$(rand 24)Aa1"; fi
      validate_password "$ADMIN_PASSWORD" || die "$(t err_admin_pw)"

      if [[ "$mode" == single ]]; then
        : # SECRET_KEY fetched automatically from /api/keygen
      fi
      if [[ "$mode" == panel ]]; then
        if [[ -z "${EDGE_ADDRESS:-}" && $AUTO_YES -eq 0 ]]; then read -r -p "$(t prompt_edge_ip)" EDGE_ADDRESS; fi
        if [[ -n "${EDGE_ADDRESS:-}" ]]; then
          ask DOMAIN_NODE "$(t ask_node_domain)" "$DOMAIN_REALITY" validate_domain
          : # SECRET_KEY fetched automatically from /api/keygen
        fi
      fi
      ask_protocols
      ;;
    edge|node)
      ask PANEL_IP "$(t ask_panel_ip)" '' validate_ip
      ask DOMAIN_REALITY "$(t ask_reality)" '' validate_domain
      ask ADMIN_EMAIL "$(t ask_email)" '' validate_email
      ask NODE_SECRET_KEY "$(t ask_secret)" ''
      ask_protocols
      ;;
    *) die "$(t err_unknown_mode "$mode")";;
  esac
}

usage(){
  cat <<EOF2
$(t help_title "$VERSION")

$(t help_menu)
$(t help_priv)

$(t help_install)
$(t help_single "$0")
$(t help_panel "$0")
$(t help_node "$0")

$(t help_one)
  $0 install single --yes DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com

$(t help_two)
  $0 install panel --yes DOMAIN_PANEL=panel.example.com DOMAIN_SUB=sub.example.com DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com
  $0 install node --yes PANEL_IP=203.0.113.10 DOMAIN_REALITY=reality.example.com ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY='node_secret'

$(t help_proto)
$(t help_all)
$(t help_real)
$(t help_hy2)
$(t help_grpc)
$(t help_xhttp)
$(t help_bind "$0")
$(t help_bind2 "$0")

$(t help_nt)
$(t help_nt_add "$0")
$(t help_nt_rm "$0")
$(t help_nt_apply "$0")
$(t help_nt_real "$0")

$(t help_ops)
$(t help_ops_line "$0")
$(t help_ops2 "$0")
$(t help_core "$0")
$(t help_stealth "$0")
$(t help_cli "$0")
$(t help_lang "$0")
$(t help_urls "$0")
$(t help_os)

$(t help_addons)
$(t help_addon_line "$0")
$(t help_community "$0")
$(t help_self "$0")
$(t help_check "$0")
$(t help_noupdate)
$(t help_version "$0")
$(t help_addnode "$0")
$(t help_users "$0")
$(t help_nctl "$0")
$(t help_tg "$0")
$(t help_bremote "$0")
$(t help_certs "$0")
$(t help_fw "$0")
$(t help_admin "$0")

$(t help_conv)
  $CONVERTER_URL
EOF2
  show_credits
}

print_menu(){
  init_ui_colors
  HYDRATE_QUIET=1 hydrate_install_state
  local protos='Reality' pc sc ns
  [[ ${HYSTERIA2:-0} -eq 1 ]] && protos+=' · Hysteria2'
  [[ ${ENABLE_GRPC:-0} -eq 1 ]] && protos+=' · gRPC'
  [[ ${ENABLE_XHTTP:-0} -eq 1 ]] && protos+=' · xHTTP'
  if [[ -n "${DOMAIN_PANEL:-}" ]]; then
    pc="$(probe_http_code "$API_LOCAL/auth/status" \
      -H 'X-Forwarded-For: 127.0.0.1' -H 'X-Forwarded-Proto: https' \
      -H "Host: ${DOMAIN_PANEL}")"
    sc="$(probe_http_code http://127.0.0.1:3010/ \
      -H 'X-Forwarded-For: 127.0.0.1' -H 'X-Forwarded-Proto: https' \
      -H "Host: ${DOMAIN_SUB:-localhost}")"
    ns="$(docker inspect -f '{{.State.Status}}' remnanode 2>/dev/null || echo off)"
  fi
  printf '\n'
  printf '%s╔══════════════════════════════════════════════════════════════╗%s\n' "$U_BLUE$U_BOLD" "$U_RESET"
  printf '%s║%s  %s%s%s\n' "$U_BLUE$U_BOLD" "$U_RESET" "$U_BOLD$U_SKY" "$(t menu_header "$VERSION")" "$U_RESET"
  printf '%s║%s  %s%s%s\n' "$U_BLUE$U_BOLD" "$U_RESET" "$U_BLUE" "$(t menu_author)" "$U_RESET"
  printf '%s║%s  %s%s%s\n' "$U_BLUE$U_BOLD" "$U_RESET" "$U_DIM$U_SKY" "$(t menu_modules)" "$U_RESET"
  printf '%s║%s  %s%s%s\n' "$U_BLUE$U_BOLD" "$U_RESET" "$U_DIM" "$(t menu_langline)" "$U_RESET"
  printf '%s║%s  %s%s%s\n' "$U_BLUE$U_BOLD" "$U_RESET" "$U_DIM" "$(t menu_proto "$protos")" "$U_RESET"
  printf '%s╚══════════════════════════════════════════════════════════════╝%s\n' "$U_BLUE$U_BOLD" "$U_RESET"
  if [[ -n "${DOMAIN_PANEL:-}" ]]; then
    printf '  panel %s   sub %s   node %s%s%s\n' "$(health_dot "$pc")" "$(health_dot "$sc")" "$U_DIM" "$ns" "$U_RESET"
    printf '  %s%s%s\n' "$U_DIM" "$(t menu_converter "$CONVERTER_URL")" "$U_RESET"
  else
    printf '  %s%s%s\n' "$U_DIM" "$(t menu_health_na)" "$U_RESET"
  fi
  if [[ ${UPDATE_AVAILABLE:-0} -eq 1 ]]; then
    printf '  %s%s%s\n' "$U_YELLOW$U_BOLD" "$(t upd_menu "$REMOTE_VERSION")" "$U_RESET"
  elif [[ -n "${REMOTE_VERSION:-}" ]]; then
    printf '  %s%s%s\n' "$U_DIM" "$(t upd_ok_line "$VERSION")" "$U_RESET"
  fi
  print_menu_certs
  menu_section(){ echo; printf '  %s▸ %s%s\n' "$U_BLUE$U_BOLD" "$1" "$U_RESET"; }
  menu_row(){
    printf "    %s%2s%s  %s%s%s\n" "$U_BLUE$U_BOLD" "$1" "$U_RESET" "$U_BOLD" "$2" "$U_RESET"
    if [[ -n "${3:-}" ]]; then
      printf "        %s%s%s\n" "$U_SKY" "$3" "$U_RESET"
    fi
  }
  menu_section "$(t menu_sec_install)"
  menu_row 1 "$(t m1)" "$(t d1)"
  menu_row 2 "$(t m2)" "$(t d2)"
  menu_row 3 "$(t m3)" "$(t d3)"
  menu_row 4 "$(t m4)" "$(t d4)"
  menu_section "$(t menu_sec_ops)"
  menu_row 5 "$(t m5)" "$(t d5)"
  menu_row 6 "$(t m6)" "$(t d6)"
  menu_row 7 "$(t m7)" "$(t d7)"
  menu_row 8 "$(t m8)" "$(t d8)"
  menu_row 9 "$(t m9)" "$(t d9)"
  menu_row 10 "$(t m10)" "$(t d10)"
  menu_row 11 "$(t m11)" "$(t d11)"
  menu_row 12 "$(t m12)" "$(t d12)"
  menu_row 13 "$(t m13)" "$(t d13)"
  menu_row 14 "$(t m14)" "$(t d14)"
  menu_row 15 "$(t m15)" "$(t d15)"
  menu_section "$(t menu_sec_extra)"
  menu_row 16 "$(t m16)" "$(t d16)"
  menu_row 17 "$(t m17)" "$(t d17)"
  menu_row 18 "$(t m18)" "$(t d18)"
  menu_row 19 "$(t m19)" "$(t d19)"
  menu_row 20 "$(t m20)" "$(t d20)"
  menu_row 21 "$(t m21)" "$(t d21)"
  menu_row 22 "$(t m22)" "$(t d22)"
  menu_row 23 "$(t m23)" "$(t d23)"
  menu_row 24 "$(t m24)" "$(t d24)"
  menu_row 25 "$(t m25)" "$(t d25)"
  menu_row 26 "$(t m26)" "$(t d26)"
  menu_row 27 "$(t m27)" "$(t d27)"
  menu_row 28 "$(t m28)" "$(t d28)"
  menu_row 29 "$(t m29)" "$(t d29)"
  menu_row 30 "$(t m30)" "$(t d30)"
  menu_row 31 "$(t m31)" "$(t d31)"
  menu_row 32 "$(t m32)" "$(t d32)"
  menu_row 0 "$(t m0)" ""
  echo
  echo "${U_DIM}$(t menu_hint)${U_RESET}"
}

existing_install_choice(){
  local choice
  already_installed || return 0
  [[ $AUTO_YES -eq 1 ]] && return 0
  echo
  echo "${U_BOLD}$(t existing_title)${U_RESET}"
  echo "$(t existing_1)"
  echo "$(t existing_2)"
  echo "$(t existing_3)"
  echo "$(t existing_0)"
  read -r -p "$(t prompt_choice)" choice
  case "$choice" in
    1) repair; show_urls; return 1 ;;
    2) apply_protocols; return 1 ;;
    3) return 0 ;;
    *) echo "$(t err_cancelled)"; return 1 ;;
  esac
}

menu_install(){
  local mode="$1"
  require_root
  if ! existing_install_choice; then
    menu_pause
    return 0
  fi
  wizard "$mode"
  case "$mode" in
    single) install_single ;;
    panel) install_panel ;;
    node|edge) install_edge ;;
  esac
  show_credits
  menu_pause
}

interactive_menu(){
  local choice name arch core_choice
  if [[ $RW_LANG_SAVED -eq 0 && $RW_LANG_CLI -eq 0 && $AUTO_YES -eq 0 ]]; then
    choose_language
  fi
  maybe_prompt_self_update
  while true; do
    print_menu
    read -r -p "$(t prompt_choice)" choice
    case "$choice" in
      1) menu_install single ;;
      2) menu_install panel ;;
      3) menu_install node ;;
      4) require_root; ask_protocols; apply_protocols; menu_pause ;;
      5) status; menu_pause ;;
      6) doctor; menu_pause ;;
      7) require_root; repair; menu_pause ;;
      8)
        read -r -p "$(t prompt_logs)" name || true
        svc_logs "${name:-}"
        ;;
      9) require_root; compose_action up; menu_pause ;;
      10) require_root; compose_action down; menu_pause ;;
      11) require_root; compose_action restart; ok "$(t services_restarted)"; menu_pause ;;
      12) require_root; backup; menu_pause ;;
      13)
        require_root
        read -r -p "$(t prompt_restore)" arch
        restore "${arch:?}"
        menu_pause
        ;;
      14) require_root; update; menu_pause ;;
      15) require_root; uninstall; menu_pause ;;
      16)
        require_root
        read -r -p "$(t prompt_core)" core_choice
        core_choice="${core_choice:-1}"
        if [[ "$core_choice" == 2 ]]; then
          restore_xray_core "${BASE}/node"
        else
          install_xray_core "${BASE}/node" "${XCORE_SOURCE:-official}"
        fi
        menu_pause
        ;;
      17)
        echo "$(t addon_a)"
        echo "$(t addon_b)"
        echo "$(t addon_c)"
        echo "$(t addon_d)"
        echo "$(t addon_e)"
        echo "$(t addon_f)"
        read -r -p "$(t prompt_addon)" choice
        case "$choice" in
          a) install_upstream_addon remnawave ;;
          b) install_upstream_addon remnanode ;;
          c) install_upstream_addon selfsteal ;;
          d) install_upstream_addon wtm ;;
          e) install_upstream_addon netbird ;;
          f) install_upstream_addon egames ;;
          *) echo "$(t err_unknown_item)" ;;
        esac
        menu_pause
        ;;
      18) require_root; enable_panel_stealth; menu_pause ;;
      19) require_root; install_cli; menu_pause ;;
      20)
        echo "$CONVERTER_URL"
        command -v xdg-open >/dev/null && xdg-open "$CONVERTER_URL" 2>/dev/null || true
        menu_pause
        ;;
      21) usage; menu_pause ;;
      22) choose_language ;;
      23) urls_and_optional_admin; menu_pause ;;
      24) community_update_menu; menu_pause ;;
      25) node_transports_menu; menu_pause ;;
      26) script_update_menu; menu_pause ;;
      27) add_node_menu; menu_pause ;;
      28) users_menu; menu_pause ;;
      29) node_control_menu; menu_pause ;;
      30) alerts_backup_menu; menu_pause ;;
      31) certs_menu; menu_pause ;;
      32) firewall_menu; menu_pause ;;
      0|q|Q) exit 0 ;;
      *) echo "$(t err_unknown_item)" ;;
    esac
  done
}

main(){
  local args=() mode n
  elevate_if_needed "$@"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|-y) AUTO_YES=1; shift;;
      --dry-run) DRY_RUN=1; shift;;
      --hysteria2) HYSTERIA2=1; PROTOCOLS_EXPLICIT=1; shift;;
      --grpc) ENABLE_GRPC=1; PROTOCOLS_EXPLICIT=1; shift;;
      --xhttp) ENABLE_XHTTP=1; PROTOCOLS_EXPLICIT=1; shift;;
      --all-protocols) enable_all_protocols; PROTOCOLS_EXPLICIT=1; shift;;
      --reality-only) HYSTERIA2=0; ENABLE_GRPC=0; ENABLE_XHTTP=0; PROTOCOLS_EXPLICIT=1; shift;;
      --monitoring) MONITORING=1; shift;;
      --telegram-alerts) TELEGRAM_ALERTS=1; shift;;
      --no-bbr) BBR=0; shift;;
      --disable-ipv6) DISABLE_IPV6=1; shift;;
      --selfsteal-template) SELFSTEAL=1; SELFSTEAL_TEMPLATE="${2:?}"; shift 2;;
      --xray-core) XCORE_SOURCE="${2:?}"; shift 2;;
      --admin-ip) ADMIN_IP="${2:?}"; shift 2;;
      --backup-remote) BACKUP_REMOTE="${2:?}"; shift 2;;
      --lang|--language)
        RW_LANG_CLI=1
        set_ui_lang "${2:?}"
        shift 2;;
      --lang=*|--language=*)
        RW_LANG_CLI=1
        set_ui_lang "${1#*=}"
        shift;;
      --lang\ *|--language\ *)
        # 1.4.0 self-update restart with IFS=$'\n\t' glued `--lang ru` into one word.
        RW_LANG_CLI=1
        set_ui_lang "${1#* }"
        shift;;
      --os-upgrade) FORCE_OS_UPGRADE=1; shift;;
      --no-update-check|--skip-update-check) SKIP_UPDATE_CHECK=1; shift;;
      *=*) export "$1"; shift;;
      *) args+=("$1"); shift;;
    esac
  done
  set -- "${args[@]}"
  if n="$(normalize_lang "${RW_LANG:-}")"; then RW_LANG="$n"; fi
  HYDRATE_QUIET=1 hydrate_install_state
  case "${1:-}" in
    ''|menu) interactive_menu ;;
    install)
      require_root; mkdir -p "$BACKUP_BASE"; touch "$LOG"; chmod 600 "$LOG"
      mode="${2:-${MODE:-single}}"
      [[ "$mode" == node ]] && mode=edge
      if [[ -z "${MODE:-}" && "$mode" == single && -n "${EDGE_ADDRESS:-}" ]]; then mode=panel; fi
      wizard "$mode"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "$(t dry_run "$mode" "${DOMAIN_PANEL:-}" "${DOMAIN_SUB:-}" "${DOMAIN_REALITY:-}" "$HYSTERIA2" "$ENABLE_GRPC" "$ENABLE_XHTTP")"
        preflight "$mode"
        install_base
        configure_security
        configure_kernel
        write_firewall "$mode"
        configure_admin_ip
        exit 0
      fi
      case "$mode" in single) install_single;; panel) install_panel;; edge) install_edge;; *) die "$(t err_unknown_mode "$mode")";; esac
      show_credits
      ;;
    protocols|bind) apply_protocols ;;
    node-transports|transports) node_transports_cli "${2:-menu}" "${3:-}" ;;
    doctor) require_root; doctor ;;
    repair) require_root; repair ;;
    status) status 2>/dev/null || true ;;
    backup) require_root; backup ;;
    update) require_root; update ;;
    up) require_root; compose_action up ;;
    down) require_root; compose_action down ;;
    restart) require_root; compose_action restart ;;
    logs) svc_logs "${2:-}" ;;
    stealth) require_root; enable_panel_stealth ;;
    install-script) require_root; install_cli ;;
    core-update) require_root; install_xray_core "${2:-$BASE/node}" "${XCORE_SOURCE:-official}" ;;
    core-restore) require_root; restore_xray_core "${2:-$BASE/node}" ;;
    checker-install) require_root; install_xray_checker ;;
    addon) require_root; install_upstream_addon "${2:?$(t err_addon)}" ;;
    add-node|add_node) add_node_menu ;;
    users|user) users_cli "${2:-list}" "${3:-}" ;;
    nodes|node-ctl|node-control) node_control_cli "${2:-list}" "${3:-}" "${4:-}" ;;
    telegram) 
      require_root
      HYDRATE_QUIET=1 hydrate_install_state
      case "${2:-}" in
        enable) telegram_enable_interactive ;;
        disable) telegram_disable_now ;;
        test) telegram_test_now ;;
        *) alerts_backup_menu ;;
      esac
      ;;
    backup-remote)
      require_root
      HYDRATE_QUIET=1 hydrate_install_state
      if [[ -n "${2:-}" ]]; then backup_remote_enable "$2"; else backup_remote_run_now; fi
      ;;
    certs|certificates)
      require_root
      HYDRATE_QUIET=1 hydrate_install_state
      case "${2:-}" in
        renew) certs_renew_now ;;
        force) certs_force_renew ;;
        *) certs_show ;;
      esac
      ;;
    firewall|ufw)
      require_root
      HYDRATE_QUIET=1 hydrate_install_state
      detect_install_mode
      if [[ -n "${2:-}" ]]; then
        validate_ip "$2" || die "$(t err_invalid ADMIN_IP "$2")"
        ADMIN_IP="$2"
        persist_manager ADMIN_IP "$ADMIN_IP"
        firewall_rebuild_now
      else
        firewall_menu
      fi
      ;;
    admin-login|admin_login) show_admin_login_once "${2:-}" ;;
    community-update|refresh-addons) require_root; refresh_community_modules ;;
    self-update) require_root; self_update ;;
    check-update|check-updates) check_update_cli "${2:-}" || exit $? ;;
    restore) require_root; restore "${2:?$(t err_restore_arg)}" ;;
    uninstall) require_root; uninstall ;;
    lang|language) set_ui_lang "${2:?en|ru}" ;;
    urls|health) show_urls ;;
    credits|авторы) show_credits ;;
    help|-h|--help) usage ;;
    --version|-V|version) print_version ;;
    *) unknown_cmd "${1:-}" ;;
  esac
}
main "$@"
