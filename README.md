# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.2-prod`

## Что автоматизирует

- Single-VDS и Multi-VDS (Panel + Edge);
- Docker Compose для Panel, Node и Subscription Page;
- Nginx SNI routing на TCP/443;
- VLESS + Reality через Config Profile;
- Let's Encrypt + ECDSA;
- UFW, fail2ban, unattended-upgrades и ротацию логов;
- healthcheck, backup/restore, certificate renewal и update;
- BBR и опциональное отключение IPv6;
- Prometheus, node-exporter и cAdvisor;
- отдельный Hysteria2 через sing-box;
- upstream add-ons;
- управление дополнительным Xray core;
- внешний Xray Checker.

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.2-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

Multi-VDS:

```bash
sudo bash remnawave-manager.sh install panel
sudo bash remnawave-manager.sh install edge
```

## DNS

Single-VDS:

| Имя | Назначение |
|---|---|
| `panel.example.com` | Panel |
| `sub.example.com` | Subscription Page |
| `reality.example.com` | Reality SNI |

Multi-VDS:

- `panel.example.com` -> Panel IP;
- `sub.example.com` -> Panel IP;
- `reality.example.com` -> Edge IP.

## Порты

Публично:

- SSH-порт;
- TCP/80;
- TCP/443;
- UDP/8443 только при Hysteria2;
- TCP/2222 на Edge только с IP Panel.

Backend-порты и локальные monitoring-порты наружу не открываются.

## Обслуживание

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh update
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

`restore` извлекает PostgreSQL dump из самого backup-архива, поэтому обычные и `.age`-backup восстанавливаются одинаково.

## Hysteria2

```bash
sudo bash remnawave-manager.sh install single --hysteria2
```

Hysteria2 запускается отдельно через sing-box на UDP/8443 и не является Xray inbound.

## Мониторинг

```bash
sudo bash remnawave-manager.sh install single --monitoring
```

Monitoring-сервисы используют локальные порты.

## Upstream add-ons

```bash
sudo bash remnawave-manager.sh addon remnawave
sudo bash remnawave-manager.sh addon remnanode
sudo bash remnawave-manager.sh addon selfsteal
sudo bash remnawave-manager.sh addon wtm
sudo bash remnawave-manager.sh addon netbird
sudo bash remnawave-manager.sh addon egames
```

Это сторонний код. Перед production-запуском просматривайте источники.

## Xray core

```bash
sudo bash remnawave-manager.sh core-update
sudo bash remnawave-manager.sh core-restore
```

## Безопасность

Не публикуйте GitHub PAT, Remnawave API tokens, Node `SECRET_KEY`, пароли PostgreSQL/администратора, age private key или Hysteria2 credentials.

После сохранения секретов удалите:

```bash
sudo rm -f /opt/remnawave/credentials.txt
```

## Контрольная сумма

```text
45b7039466597a34220ca3c32a0dcc1080e759611b6e8a43735fb9b2310781dd  remnawave-manager-v25.1.2-prod.sh
```

Также доступна в [SHA256SUMS](SHA256SUMS).

## Production status

`25.1.2-prod` прошёл:

- `bash -n`;
- `--help`;
- dry-run `single`;
- dry-run `panel`;
- dry-run `edge`;
- статические assertions.

**Реальный VDS/Docker/ACME deployment пока не выполнен.** Перед production обязателен тест на чистом VDS.

Подробности: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md) и [CHANGELOG.md](CHANGELOG.md).

Репозиторий: https://github.com/booarkz-cpu/remnawave-manager

