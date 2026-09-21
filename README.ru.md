# Remnawave Manager

[English](README.md) · [Русский](README.ru.md)

Production-установщик [Remnawave](https://docs.rw) на Debian/Ubuntu. Интерактивное меню с описанием каждой функции. Язык интерфейса: **русский** или **English**.

**Текущая версия:** `25.2.2-prod`

Автор основной линии: **booarkz-cpu**. В скрипт добавлены функции из [Rezzosoft KVN](https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2), [eGamesAPI](https://github.com/eGamesAPI/remnawave-reverse-proxy) и [DigneZzZ](https://github.com/DigneZzZ/remnawave-scripts). Авторство исходных проектов сохранено — см. [CREDITS.md](CREDITS.md).

Профиль Xray, inbound’ы, ноды, хосты, сквад AUTO и пользователь AUTO создаются через API. Панель и конвертер для привязки протоколов править не нужно.

## Быстрый старт

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.2-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sudo bash remnawave-manager.sh
```

Без аргументов открывается меню. При первом запуске спрашивает **English** или **Русский** (сохраняется в `/opt/remnawave/manager.env`). Позже — пункт 22 меню или:

```bash
sudo bash remnawave-manager.sh --lang ru
sudo bash remnawave-manager.sh --lang en
```

По умолчанию включаются все транспорты: Reality, Hysteria2, gRPC и xHTTP.

## Меню (все функции)

| № | Функция | Что делает |
| --- | --- | --- |
| 1 | Полная установка | Панель + нода на одном VDS, nginx SNI, Corgi SelfSteal, сертификаты, автопривязка |
| 2 | Только панель | Панель + страница подписки + HTTPS; `EDGE_ADDRESS` сразу регистрирует ноду |
| 3 | Только нода | remnanode в host-сети, SNI-сайт Reality; `SECRET_KEY` из `credentials.txt` панели |
| 4 | Автопривязка протоколов | Обновляет AUTO-PROFILE, вешает inbound’ы, создаёт хосты и сквад AUTO (без UI панели) |
| 5 | Состояние | Контейнеры, nginx/fail2ban, systemd-таймеры |
| 6 | Диагностика | API панели, страница подписки, порты, UFW |
| 7 | Repair | Переписывает proxy-заголовки и SelfSteal без удаления Docker/БД |
| 8 | Логи | Журнал remnawave / remnanode / subscription-page |
| 9 | Up | `docker compose up` всех стеков |
| 10 | Down | `docker compose down` (данные сохраняются) |
| 11 | Перезапуск | Перезапуск всех compose-стеков Remnawave |
| 12 | Backup | Архив в `/var/backups/remnawave` |
| 13 | Restore | Восстановление из `.tgz` или `.age` |
| 14 | Обновление | Backup, pull образов (панель → нода → подписка), проверка API |
| 15 | Удаление | Снимает сервисы и nginx vhost; backup’ы остаются |
| 16 | Ядро Xray | Свой бинарник или штатный из образа |
| 17 | Модули | CLI DigneZzZ, SelfSteal, WARP/Tor, NetBird, eGames reverse-proxy |
| 18 | Скрытый вход | Cookie/query-затвор для `/auth/login` (идея eGames) |
| 19 | Команда CLI | Копирует скрипт в `/usr/local/bin/remnawave-manager` |
| 20 | Конвертер | Необязательный JSON-помощник Rezzosoft (для привязки не нужен) |
| 21 | Авторство / справка | Авторы и полная справка CLI |
| 22 | Язык | Русский или English |
| 0 | Выход | — |

## Режимы установки

| Команда | Что ставится |
| --- | --- |
| `install single` | Панель + нода на одном VDS |
| `install panel` | Только панель; к ней потом подключаются ноды |
| `install node` | Только нода на отдельном сервере (`SECRET_KEY` из `/opt/remnawave/credentials.txt` на панели) |

Два сервера:

```bash
# Панель (EDGE_ADDRESS — IP ноды, чтобы карточка Node создалась сразу)
sudo bash remnawave-manager.sh --lang ru install panel --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com \
  EDGE_ADDRESS=203.0.113.20

# Нода (другой VDS)
sudo bash remnawave-manager.sh --lang ru install node --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY='секрет_из_credentials.txt'
```

## Протоколы

По умолчанию включаются все. Привязка к панели — автоматически.

- Reality (VLESS TCP, SNI на 443)
- Hysteria2 UDP/443 в профиле Xray + sing-box UDP/8443
- VLESS gRPC + Reality TCP/8443
- VLESS xHTTP + Reality TCP/4443

Флаги: `--all-protocols` (то же, что по умолчанию), `--reality-only`, `--hysteria2`, `--grpc`, `--xhttp`.

На уже установленной системе: `sudo bash remnawave-manager.sh protocols` (синоним: `bind`) или пункт 4 меню.

## Обслуживание

`status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `core-update`, `stealth`, `addon remnawave|remnanode|selfsteal|wtm|netbird|egames`.

Подробности: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md), [CHANGELOG.md](CHANGELOG.md), [SHA256SUMS](SHA256SUMS).
