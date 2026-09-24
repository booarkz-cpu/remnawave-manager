#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

mkdir -p docs/wiki

cat > docs/wiki/README.md <<'EOF'
# Remnawave Manager Wiki

**Remnawave Manager** — Bash-менеджер для установки, настройки, обслуживания и обновления Remnawave Panel и Remnawave Node.

Автор проекта: **Corgi Lusi / Корги Люси**

## Языки

- [Русский](README.ru.md)
- [English](README.en.md)
- [Українська](README.uk.md)

## Возможности

Менеджер объединяет в одном CLI установку Panel/Node, управление транспортами, диагностику, backup/restore, обновления Remnawave и Xray, add-ons, сертификаты, firewall, Telegram/remote backup и другие функции проекта.

## Основные пункты меню

| № | Функция | CLI |
|---:|---|---|
| 0 | Выход | — |
| 1 | Полная установка | `install single` |
| 2 | Только Panel | `install panel` |
| 3 | Только Node | `install node` |
| 4 | Auto-bind / транспорты | `protocols`, `bind` |
| 5 | Status | `status` |
| 6 | Doctor | `doctor` |
| 7 | Repair | `repair` |
| 8 | Logs | `logs` |
| 9 | Up | `up` |
| 10 | Down | `down` |
| 11 | Restart | `restart` |
| 12 | Backup | `backup` |
| 13 | Restore | `restore` |
| 14 | Обновление Remnawave | `update` |
| 15 | Uninstall | `uninstall` |
| 16 | Xray Core | `core-update` |
| 17 | Add-ons | `addon` |
| 18 | Stealth Login | `stealth` |
| 19 | Установка CLI | `install-script` |
| 20 | Converter | `converter` |
| 21 | Help / Credits | — |
| 22 | Language | — |
| 23 | URLs | — |
| 24 | Community Update | `community-update` |
| 25 | Node transports | `node-transports` |
| 26 | Обновление Manager | `check-update`, `self-update` |
| 27 | Add Node | `add-node` |
| 28 | Users | `users` |
| 29 | Nodes | `nodes` |
| 30 | Alerts / Remote Backup | `telegram`, `backup-remote` |
| 31 | Certificates | `certs` |
| 32 | Firewall | `firewall` |
| 33 | Subscription Stub | `sub-stub` |

## Транспорты

- VLESS Reality TCP — `443`;
- Hysteria2 UDP — `443`;
- sing-box UDP — `8443`;
- VLESS gRPC Reality TCP — `8443`, путь `/grpc`;
- VLESS xHTTP Reality TCP — `4443`, путь `/xhttp`.

Флаги установки:

```text
--all-protocols
--reality-only
--hysteria2
--grpc
--xhttp
```

Полное применение транспортов:

```bash
remnawave-manager protocols
remnawave-manager bind
```

## Архитектура

Panel и Node могут работать на одном VPS или на разных серверах.

```text
Internet
   |
 nginx
   |
Remnawave Panel
   |
Remnawave Node
   |
Xray / transports
```

## Требования

- Debian / Ubuntu;
- публичный IPv4;
- домен Panel;
- домен подписки;
- домен/SNI для Reality;
- свободные TCP-порты `80` и `443`;
- email для Let's Encrypt.

Типовая DNS-схема:

```text
Panel domain        -> Panel IP
Subscription domain -> Panel IP
Reality/SNI domain  -> Node IP
```

## Основные каталоги

```text
/opt/remnawave/
/opt/remnawave/subscription/
/opt/remnawave/node/
/opt/remnawave-edge/
/opt/remnawave/hysteria2/
/opt/remnawave-addons/
/var/backups/remnawave/
/var/log/remnawave-manager.log
/var/www/sub-site/
/usr/local/bin/remnawave-manager
```

Credentials могут находиться в:

```text
/opt/remnawave/credentials.txt
```

**Не публикуйте этот файл.**

## Обновления

### Manager

```bash
remnawave-manager check-update
remnawave-manager self-update
```

### Remnawave

```bash
remnawave-manager update
```

### Xray Core

```bash
remnawave-manager core-update
```

Это три разных операции.

## Диагностика

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
remnawave-manager repair
remnawave-manager restart
```

## Backup

```bash
remnawave-manager backup
remnawave-manager restore
```

Резервные копии:

```text
/var/backups/remnawave/
```

## Безопасность

Никогда не публикуйте:

- API tokens;
- `SECRET_KEY`;
- пароль PostgreSQL;
- `credentials.txt`;
- приватный age key;
- Telegram Bot Token;
- приватные TLS-ключи;
- секреты `.env`.

Не открывайте внутренний Panel-порт `3000` напрямую без необходимости. Используйте nginx/reverse proxy и корректные forwarded headers.

## Рекомендуемый порядок

1. Настроить DNS.
2. Выполнить установку.
3. Проверить `status`.
4. Запустить `doctor`.
5. Проверить transports.
6. Проверить URLs.
7. Проверить Node.
8. Создать backup.
9. При необходимости настроить alerts/remote backup.
EOF

cat > docs/wiki/README.ru.md <<'EOF'
# Remnawave Manager — Wiki на русском

## Что это

Remnawave Manager — CLI-менеджер для развёртывания и обслуживания Remnawave Panel/Node.

Проект написан на Bash и предназначен прежде всего для Debian/Ubuntu.

Автор: **Corgi Lusi / Корги Люси**

## Установка

Полная установка:

```bash
remnawave-manager install single
```

Panel отдельно:

```bash
remnawave-manager install panel
```

Node отдельно:

```bash
remnawave-manager install node
```

## Меню

### 0 — Exit
Выход из Manager.

### 1 — Full Install
Полная установка Panel + необходимых компонентов + Node/транспортов согласно выбранной конфигурации.

### 2 — Panel Only
Установка только Remnawave Panel. Используется, когда Node находится на другом сервере.

### 3 — Node Only
Установка Node без Panel.

### 4 — Auto-bind
Автоматическая настройка и привязка транспортов:

```bash
remnawave-manager protocols
remnawave-manager bind
```

### 5 — Status
Показывает состояние установленных компонентов и сервисов.

### 6 — Doctor
Диагностика конфигурации и распространённых проблем.

### 7 — Repair
Автоматическое восстановление известных проблем.

### 8 — Logs
Просмотр логов Manager и связанных сервисов.

Основной лог:

```text
/var/log/remnawave-manager.log
```

### 9 / 10 / 11 — Up / Down / Restart

```bash
remnawave-manager up
remnawave-manager down
remnawave-manager restart
```

### 12 / 13 — Backup / Restore

```bash
remnawave-manager backup
remnawave-manager restore
```

### 14 — Remnawave Update

Обновление образов Remnawave. Это не обновление Manager и не обновление Xray.

### 15 — Uninstall

Удаление установленного окружения. Перед удалением рекомендуется сделать backup.

### 16 — Xray Core

```bash
remnawave-manager core-update
```

### 17 — Add-ons
Установка и управление дополнительными компонентами проекта.

### 18 — Stealth Login
Дополнительный механизм скрытого/защищённого доступа согласно конфигурации проекта.

### 19 — Install CLI

```bash
remnawave-manager install-script
```

### 20 — Converter
Инструменты конвертации, предусмотренные Manager.

### 21 — Help / Credits
Справка и информация об авторах/проекте.

### 22 — Language
Переключение языка интерфейса.

### 23 — URLs
Показывает используемые URL и адреса компонентов.

### 24 — Community Update
Обновление community-функций проекта.

### 25 — Node Transports

Поддерживаются:

- VLESS Reality TCP `443`;
- Hysteria2 UDP `443`;
- sing-box UDP `8443`;
- VLESS gRPC Reality TCP `8443`;
- VLESS xHTTP Reality TCP `4443`.

gRPC:

```text
/grpc
```

xHTTP:

```text
/xhttp
```

### 26 — Manager Update

```bash
remnawave-manager check-update
remnawave-manager self-update
```

### 27 — Add Node
Добавление дополнительного Node.

### 28 — Users
Управление пользователями через возможности Manager.

### 29 — Nodes
Управление Node и связанные операции.

### 30 — Alerts / Remote Backup

```bash
remnawave-manager telegram
remnawave-manager backup-remote
```

### 31 — Certificates
Управление сертификатами.

### 32 — Firewall
Настройка firewall.

### 33 — Subscription Stub
Функции Subscription Stub.

## Безопасность

Не передавайте третьим лицам:

```text
/opt/remnawave/credentials.txt
```

Также нельзя публиковать API tokens, пароли БД, `SECRET_KEY`, Telegram Bot Token, приватные ключи и другие секреты.

Внутренний Panel-порт `3000` не следует без необходимости выставлять напрямую в Интернет.

## Troubleshooting

При проблеме:

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
remnawave-manager repair
```

После изменения конфигурации:

```bash
remnawave-manager restart
```
EOF

cat > docs/wiki/README.en.md <<'EOF'
# Remnawave Manager — Wiki

Remnawave Manager is a Bash CLI manager for deploying, configuring, maintaining and updating Remnawave Panel and Remnawave Node.

Author: **Corgi Lusi**

## Installation

```bash
remnawave-manager install single
remnawave-manager install panel
remnawave-manager install node
```

Recommended prerequisites:

- Debian/Ubuntu;
- public IPv4;
- Panel domain;
- subscription domain;
- Reality/SNI domain;
- TCP ports `80` and `443` available;
- email for Let's Encrypt.

## Main menu

| # | Function | CLI |
|---:|---|---|
| 0 | Exit | — |
| 1 | Full installation | `install single` |
| 2 | Panel only | `install panel` |
| 3 | Node only | `install node` |
| 4 | Auto-bind / protocols | `protocols`, `bind` |
| 5 | Status | `status` |
| 6 | Doctor | `doctor` |
| 7 | Repair | `repair` |
| 8 | Logs | `logs` |
| 9 | Up | `up` |
| 10 | Down | `down` |
| 11 | Restart | `restart` |
| 12 | Backup | `backup` |
| 13 | Restore | `restore` |
| 14 | Remnawave update | `update` |
| 15 | Uninstall | `uninstall` |
| 16 | Xray Core | `core-update` |
| 17 | Add-ons | `addon` |
| 18 | Stealth Login | `stealth` |
| 19 | Install CLI | `install-script` |
| 20 | Converter | `converter` |
| 21 | Help / Credits | — |
| 22 | Language | — |
| 23 | URLs | — |
| 24 | Community Update | `community-update` |
| 25 | Node transports | `node-transports` |
| 26 | Manager update | `check-update`, `self-update` |
| 27 | Add Node | `add-node` |
| 28 | Users | `users` |
| 29 | Nodes | `nodes` |
| 30 | Alerts / Remote backup | `telegram`, `backup-remote` |
| 31 | Certificates | `certs` |
| 32 | Firewall | `firewall` |
| 33 | Subscription Stub | `sub-stub` |

## Supported transports

- VLESS Reality TCP — `443`;
- Hysteria2 UDP — `443`;
- sing-box UDP — `8443`;
- VLESS gRPC Reality TCP — `8443`, path `/grpc`;
- VLESS xHTTP Reality TCP — `4443`, path `/xhttp`.

Installation flags:

```text
--all-protocols
--reality-only
--hysteria2
--grpc
--xhttp
```

Full transport rebind:

```bash
remnawave-manager protocols
remnawave-manager bind
```

## Diagnostics

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
remnawave-manager repair
remnawave-manager restart
```

## Backups

```bash
remnawave-manager backup
remnawave-manager restore
```

Backup directory:

```text
/var/backups/remnawave/
```

Remote backup and Telegram integrations:

```bash
remnawave-manager telegram
remnawave-manager backup-remote
```

## Updates

Manager:

```bash
remnawave-manager check-update
remnawave-manager self-update
```

Remnawave:

```bash
remnawave-manager update
```

Xray:

```bash
remnawave-manager core-update
```

## Important paths

```text
/opt/remnawave/
/opt/remnawave/subscription/
/opt/remnawave/node/
/opt/remnawave-edge/
/opt/remnawave/hysteria2/
/opt/remnawave-addons/
/var/backups/remnawave/
/var/log/remnawave-manager.log
/var/www/sub-site/
/usr/local/bin/remnawave-manager
```

## Security

Never commit or publish:

- API tokens;
- `SECRET_KEY`;
- PostgreSQL passwords;
- `credentials.txt`;
- age private keys;
- Telegram Bot Tokens;
- TLS private keys;
- `.env` secrets.

Do not expose the internal Panel port `3000` directly unless explicitly required and secured. Use nginx/reverse proxy and correct forwarded headers.
EOF

cat > docs/wiki/README.uk.md <<'EOF'
# Remnawave Manager — Wiki українською

Remnawave Manager — Bash CLI-менеджер для встановлення, налаштування, обслуговування та оновлення Remnawave Panel і Remnawave Node.

Автор: **Corgi Lusi**

## Встановлення

```bash
remnawave-manager install single
remnawave-manager install panel
remnawave-manager install node
```

Рекомендовані вимоги:

- Debian / Ubuntu;
- публічна IPv4-адреса;
- домен Panel;
- домен підписок;
- домен/SNI для Reality;
- доступні TCP-порти `80` і `443`;
- email для Let's Encrypt.

## Основні функції

Manager підтримує встановлення Panel/Node, транспорти, status, doctor, repair, logs, up/down/restart, backup/restore, оновлення Remnawave і Xray, add-ons, certificates, firewall, Telegram та remote backup.

## Транспорти

- VLESS Reality TCP — `443`;
- Hysteria2 UDP — `443`;
- sing-box UDP — `8443`;
- VLESS gRPC Reality TCP — `8443`, шлях `/grpc`;
- VLESS xHTTP Reality TCP — `4443`, шлях `/xhttp`.

Параметри:

```text
--all-protocols
--reality-only
--hysteria2
--grpc
--xhttp
```

Повторне застосування:

```bash
remnawave-manager protocols
remnawave-manager bind
```

## Діагностика

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
remnawave-manager repair
remnawave-manager restart
```

## Резервні копії

```bash
remnawave-manager backup
remnawave-manager restore
```

Каталог:

```text
/var/backups/remnawave/
```

## Оновлення

Manager:

```bash
remnawave-manager check-update
remnawave-manager self-update
```

Remnawave:

```bash
remnawave-manager update
```

Xray:

```bash
remnawave-manager core-update
```

## Основні каталоги

```text
/opt/remnawave/
/opt/remnawave/subscription/
/opt/remnawave/node/
/opt/remnawave-edge/
/opt/remnawave/hysteria2/
/opt/remnawave-addons/
/var/backups/remnawave/
/var/log/remnawave-manager.log
/var/www/sub-site/
/usr/local/bin/remnawave-manager
```

## Безпека

Не публікуйте:

- API tokens;
- `SECRET_KEY`;
- паролі PostgreSQL;
- `credentials.txt`;
- приватні age keys;
- Telegram Bot Token;
- приватні TLS-ключі;
- секрети `.env`.

Внутрішній порт Panel `3000` не слід без потреби відкривати напряму в Інтернет. Використовуйте nginx/reverse proxy та правильні forwarded headers.
EOF

cat > docs/wiki/INSTALLATION.md <<'EOF'
# Installation Reference

## Single server

```bash
remnawave-manager install single
```

## Separate Panel and Node

Panel:

```bash
remnawave-manager install panel
```

Node:

```bash
remnawave-manager install node
```

## DNS

Verify:

- Panel hostname -> Panel IP;
- subscription hostname -> Panel IP;
- Reality/SNI hostname -> Node IP.

## Ports

Common ports include:

```text
TCP 443
UDP 443
TCP 8443
UDP 8443
TCP 4443
TCP 80
```

Only expose ports required by the selected configuration.
EOF

cat > docs/wiki/TROUBLESHOOTING.md <<'EOF'
# Troubleshooting

## First checks

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
```

Repair:

```bash
remnawave-manager repair
```

Restart:

```bash
remnawave-manager restart
```

## Transport problems

Check DNS, required TCP/UDP ports, enabled transports, certificates/Reality parameters and Node connectivity.

Reapply transports:

```bash
remnawave-manager protocols
```

or:

```bash
remnawave-manager bind
```

## Backup before repair

```bash
remnawave-manager backup
remnawave-manager repair
```

Manager log:

```text
/var/log/remnawave-manager.log
```
EOF

cat > docs/wiki/SECURITY.md <<'EOF'
# Security

Never commit secrets to Git.

Sensitive values include:

- API tokens;
- database passwords;
- `SECRET_KEY`;
- Telegram Bot Token;
- age private keys;
- TLS private keys;
- `.env` secrets;
- `/opt/remnawave/credentials.txt`.

Before committing:

```bash
git status
git diff -- docs/wiki
```

Make sure no credentials are included.

Treat backups as sensitive because they can contain credentials and configuration secrets.
EOF

cat > docs/wiki/COMMANDS.md <<'EOF'
# Command Reference

```bash
remnawave-manager install single
remnawave-manager install panel
remnawave-manager install node

remnawave-manager protocols
remnawave-manager bind

remnawave-manager status
remnawave-manager doctor
remnawave-manager repair
remnawave-manager logs

remnawave-manager up
remnawave-manager down
remnawave-manager restart

remnawave-manager backup
remnawave-manager restore

remnawave-manager update
remnawave-manager uninstall
remnawave-manager core-update

remnawave-manager addon
remnawave-manager stealth
remnawave-manager install-script
remnawave-manager converter

remnawave-manager community-update
remnawave-manager node-transports
remnawave-manager check-update
remnawave-manager self-update

remnawave-manager add-node
remnawave-manager users
remnawave-manager nodes

remnawave-manager telegram
remnawave-manager backup-remote

remnawave-manager certs
remnawave-manager firewall
remnawave-manager sub-stub
```
EOF

echo "Wiki files created:"
find docs/wiki -maxdepth 1 -type f -print | sort
echo
echo "Git status:"
git status --short