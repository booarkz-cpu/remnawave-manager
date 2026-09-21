# Remnawave Manager

Production-установщик Remnawave на Debian/Ubuntu. Интерфейс и документация на русском.

**Текущая версия:** `25.2.1-prod`

Автор основной линии: **booarkz-cpu**. В эту версию добавлены функции из скриптов [Rezzosoft KVN](https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2), [eGamesAPI](https://github.com/eGamesAPI/remnawave-reverse-proxy) и [DigneZzZ](https://github.com/DigneZzZ/remnawave-scripts). Авторство исходных проектов сохранено — см. [CREDITS.md](CREDITS.md).

Профиль Xray, inbound’ы, ноды, хосты, сквад AUTO и пользователь AUTO создаются через API. Панель и конвертер править не нужно.

## Быстрый старт

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.1-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sudo bash remnawave-manager.sh
```

Без аргументов открывается русское меню. По умолчанию ставятся все транспорты: Reality, Hysteria2, gRPC и xHTTP.

## Режимы установки

| Режим | Что ставится |
| --- | --- |
| `install single` | Панель + нода на одном VDS |
| `install panel` | Только панель; к ней потом подключаются ноды |
| `install node` | Только нода на отдельном сервере (`SECRET_KEY` из `/opt/remnawave/credentials.txt` на панели) |

Два сервера:

```bash
# Панель (EDGE_ADDRESS — IP ноды, чтобы карточка Node создалась сразу)
sudo bash remnawave-manager.sh install panel --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com \
  EDGE_ADDRESS=203.0.113.20

# Нода (другой VDS)
sudo bash remnawave-manager.sh install node --yes \
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

На уже установленной системе: `sudo bash remnawave-manager.sh protocols` (синоним: `bind`) или пункт 4 меню. Команда обновляет AUTO-PROFILE, вешает все inbound’ы на ноды, создаёт хосты с path/host/ALPN и сквад AUTO.

## Обслуживание

`status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `core-update`, `stealth`, `addon remnawave|remnanode|selfsteal|wtm|netbird|egames`.

Подробности: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md), [CHANGELOG.md](CHANGELOG.md), [SHA256SUMS](SHA256SUMS).
