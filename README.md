# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.1-prod`

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

Скачать:

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.1-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
```

Перед установкой:

```bash
bash remnawave-manager.sh --dry-run
```

Single-VDS:

```bash
sudo bash remnawave-manager.sh install single
```

Multi-VDS:

```bash
sudo bash remnawave-manager.sh install panel
sudo bash remnawave-manager.sh install edge
```

## Требования

Официальная документация Remnawave рекомендует Debian/Ubuntu и Docker с Compose. Для Panel указано минимум 2 GB RAM, рекомендуется 4 GB; для Node минимум 1 GB RAM и 1 CPU. citeturn907175search4

Официальная инструкция Node также требует, чтобы `NODE_PORT` был закрыт от внешнего доступа и доступен только с IP Panel. citeturn226976search0

## DNS

Single-VDS:

| Имя | Назначение |
|---|---|
| `panel.example.com` | Panel |
| `sub.example.com` | Subscription Page |
| `reality.example.com` | Reality SNI |

Multi-VDS:

- `panel.example.com` -> Panel IP
- `sub.example.com` -> Panel IP
- `reality.example.com` -> Edge IP

## Порты

Публично:

- SSH-порт;
- TCP/80;
- TCP/443;
- UDP/8443 только с Hysteria2.

На Edge TCP/2222 разрешается только с IP Panel.

Backend-порты Panel/Subscription и внутренние Node/monitoring-порты наружу не публикуются.

## Subscription Page

Менеджер использует `CUSTOM_SUB_PREFIX=sub` и `SUB_PUBLIC_DOMAIN=sub.example.com/sub`.

В текущем upstream `.env.sample` `TRUST_PROXY` поддерживает режимы `true/false`, число доверенных hops и CIDR; для нашей схемы с одним reverse-proxy используется `TRUST_PROXY=1`. citeturn464550search4

## Reality

Config Profile содержит VLESS + RAW + REALITY. Текущий Xray поддерживает `target`, `serverNames`, `privateKey` и `shortIds` в `realitySettings`; `target` используется для локального fallback/target. citeturn639035search0turn639035search1

## Обслуживание

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh update
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

## Hysteria2

```bash
sudo bash remnawave-manager.sh install single --hysteria2
```

Текущая документация sing-box подтверждает `masquerade` как допустимую Hysteria2 server-настройку и `http/https` URL как reverse-proxy режим. citeturn464550search0

## Мониторинг

```bash
sudo bash remnawave-manager.sh install single --monitoring
```

Prometheus и другие monitoring-сервисы привязаны к localhost-портам.

## Upstream add-ons

```bash
sudo bash remnawave-manager.sh addon remnawave
sudo bash remnawave-manager.sh addon remnanode
sudo bash remnawave-manager.sh addon selfsteal
sudo bash remnawave-manager.sh addon wtm
sudo bash remnawave-manager.sh addon netbird
sudo bash remnawave-manager.sh addon egames
```

Upstream DigneZzZ сейчас продолжает публиковать `remnawave.sh`, `remnanode.sh`, `selfsteal.sh`, `wtm.sh` и `netbird.sh`; eGames также публикует отдельный installer/reverse-proxy. citeturn296478search1turn296478search0

Сторонние add-ons выполняют сторонний код: просматривайте источник перед production-запуском.

## Xray core

```bash
sudo bash remnawave-manager.sh core-update
sudo bash remnawave-manager.sh core-restore
```

Для Torrent Blocker текущая документация Remnawave указывает минимальный Xray-Core 26.3.27. citeturn907175search8

## Backup и restore

Backup включает PostgreSQL dump и конфигурационные файлы. В `25.1.1-prod` restore также импортирует соответствующий PostgreSQL dump перед окончательным запуском стека.

Не восстанавливайте неизвестные архивы.

## Безопасность

Не публикуйте:

- GitHub PAT;
- Remnawave API tokens;
- Node `SECRET_KEY`;
- пароли;
- age private key;
- Hysteria2 credentials;
- `.env` и bootstrap-файлы.

После сохранения секретов удалите:

```bash
sudo rm -f /opt/remnawave/credentials.txt
```

## Версии

`25.1.1-prod` исправляет ошибки, найденные в `25.1.0-prod` до первого реального production VDS-теста. Используйте `25.1.1-prod` для новых установок.

Подробности: [CHANGELOG.md](CHANGELOG.md)

## Контрольная сумма

SHA-256: `4b2bb90bdc9418e25b59bd865219c378bc170c716fa2f21137fffa9adceb6bee`

Список checksum: [SHA256SUMS](SHA256SUMS)

## Важные caveats

- Автоматизация Node использует API bootstrap `/api/keygen`, а не ручной UI workflow.
- Существующий `AUTO-PROFILE` переиспользуется; полная reconciliation его содержимого по-прежнему не выполняется.
- Официальный backend compose и `.env.sample` берутся из upstream `main`, поэтому для строгой воспроизводимости стоит фиксировать версии.
- Реальный VDS/Docker/ACME runtime deployment пока не выполнялся из этой среды; перед production обязателен тест на чистом VDS.

