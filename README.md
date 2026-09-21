# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Версия:** `25.1.0-prod`

## Возможности

- Single-VDS и Multi-VDS (Panel + Edge);
- Docker Compose для Panel, Node и Subscription Page;
- Nginx SNI routing на TCP/443;
- VLESS + Reality через Config Profile;
- Let's Encrypt + ECDSA;
- UFW, fail2ban, unattended-upgrades и ротация Docker-логов;
- healthcheck, certificate renewal, backup/restore и update;
- BBR и опциональное отключение IPv6;
- Prometheus, node-exporter и cAdvisor;
- отдельный Hysteria2 через sing-box;
- upstream add-ons;
- дополнительное ядро Xray;
- внешний Xray Checker.

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.0-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --dry-run
```

### Single-VDS

```bash
sudo bash remnawave-manager.sh install single
```

Неинтерактивный запуск:

```bash
sudo bash remnawave-manager.sh install single --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

### Multi-VDS

Panel VDS:

```bash
sudo bash remnawave-manager.sh install panel
```

Edge VDS:

```bash
sudo bash remnawave-manager.sh install edge
```

## DNS и порты

Для Single-VDS обычно нужны:

| Имя | Назначение |
|---|---|
| `panel.example.com` | Panel |
| `sub.example.com` | Subscription Page |
| `reality.example.com` | Reality SNI |

Для Multi-VDS `panel` и `sub` указывают на Panel IP, а `reality` — на Edge IP.

Публично используются SSH, TCP/80 и TCP/443. UDP/8443 открывается только при включённом Hysteria2. На Edge TCP/2222 разрешается только с IP Panel.

## Обслуживание

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh update
```

Restore:

```bash
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

## Дополнительные функции

Мониторинг:

```bash
sudo bash remnawave-manager.sh install single --monitoring
```

Hysteria2:

```bash
sudo bash remnawave-manager.sh install single --hysteria2
```

Xray core:

```bash
sudo bash remnawave-manager.sh core-update
sudo bash remnawave-manager.sh core-restore
```

Upstream-модули:

```bash
sudo bash remnawave-manager.sh addon remnawave
sudo bash remnawave-manager.sh addon remnanode
sudo bash remnawave-manager.sh addon selfsteal
sudo bash remnawave-manager.sh addon wtm
sudo bash remnawave-manager.sh addon netbird
sudo bash remnawave-manager.sh addon egames
```

## Безопасность

Не публикуйте API token, Node SECRET_KEY, пароли, age private key, `.env`, bootstrap-файлы или backup-ключи.

После сохранения секретов в защищённом месте удалите локальный файл с выведенными credentials:

```bash
sudo rm -f /opt/remnawave/credentials.txt
```

Upstream add-ons являются сторонними скриптами; проверяйте их содержимое перед выполнением.

## Важные ограничения

- API-based bootstrap Node использует текущий `/api/keygen` и отличается от ручного UI-сценария.
- `AUTO-PROFILE` при повторном запуске переиспользуется и не выполняет полную reconciliation всех параметров.
- Официальные Compose и `.env.sample` берутся из текущего upstream, поэтому для строгой воспроизводимости версии рекомендуется фиксировать отдельно.
- Hysteria2 устанавливается отдельно через sing-box и не является inbound Config Profile Xray.
- Restore предназначен только для доверенных backup-архивов.

Подробная инструкция: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).

## Контрольная сумма

SHA-256 опубликован в [SHA256SUMS](SHA256SUMS).

## Лицензия

Лицензия проекта пока не указана. Не предполагайте наличие прав на коммерческое, производное или повторное распространение без разрешения автора.

## Репозиторий

https://github.com/booarkz-cpu/remnawave-manager
