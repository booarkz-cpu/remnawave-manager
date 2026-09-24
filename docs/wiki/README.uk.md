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
