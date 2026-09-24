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
