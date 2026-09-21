# Remnawave Manager

[English](README.md) · [Русский](README.ru.md)

**Полная инструкция:** [на русском](docs/GUIDE.ru.md) · [in English](docs/GUIDE.en.md)

Production-установщик [Remnawave](https://docs.rw) на Debian/Ubuntu. Интерактивное меню с описанием каждой функции. Язык: **русский** или **English**.

**Текущая версия:** `1.3.0`

Автор: **Корги Люси (Corgi Lusi)**. В скрипт добавлены функции из [Rezzosoft KVN](https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2), [eGamesAPI](https://github.com/eGamesAPI/remnawave-reverse-proxy) и [DigneZzZ](https://github.com/DigneZzZ/remnawave-scripts). Авторство исходников сохранено — [CREDITS.md](CREDITS.md).

Профиль Xray, inbound’ы, ноды, хосты, сквад **CorgiLusi** и пользователь CorgiLusi создаются через API. У каждой ноды свой config-профиль. **Default-Profile** удаляется после установки. Панель для привязки протоколов править не нужно.

Два разных обновления:

| | Файл скрипта | Образы Remnawave |
| --- | --- | --- |
| Что | `remnawave-manager.sh` | контейнеры панели / ноды / подписки |
| Как | [Обновить этот скрипт](#обновить-этот-скрипт-до-latest) | пункт **14** / `update` |

---

## Содержание

- [Быстрый старт](#быстрый-старт)
- [Обновить этот скрипт до Latest](#обновить-этот-скрипт-до-latest)
- [Меню](#меню)
- [Режимы установки](#режимы-установки)
- [Протоколы](#протоколы)
- [Обслуживание](#обслуживание)
- [Документация](#документация)

---

## Быстрый старт

Скачайте **GitHub Latest** (не `raw.githubusercontent.com/main`) и сверьте хеш:

```bash
curl -fL --retry 5 --retry-all-errors \
  https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh

curl -fL --retry 5 --retry-all-errors \
  https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/SHA256SUMS \
  -o SHA256SUMS
sha256sum remnawave-manager.sh
grep ' remnawave-manager.sh$' SHA256SUMS
```

Две суммы должны совпасть. Затем:

```bash
bash remnawave-manager.sh
```

Без аргументов открывается меню. `sudo` в команде писать не нужно — скрипт сам поднимает root. При первом запуске спрашивает **English** или **Русский** (сохраняется в `/opt/remnawave/manager.env`). Позже — пункт 22 или `--lang ru|en`.

Фиксированная 1.3.0 через jsDelivr (по желанию):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.3.0/remnawave-manager.sh \
  -o remnawave-manager.sh
# sha256: dd7ece932c3dd26a93dacc0c24249dfa1b15bb8f7bd475b5b846a6d6a933c152
```

По умолчанию включаются все транспорты: Reality, Hysteria2, gRPC и xHTTP.

Пошагово (один VDS, два VDS, DNS, файлы на диске): **[docs/GUIDE.ru.md](docs/GUIDE.ru.md)**.

---

## Обновить этот скрипт до Latest

Меняется **только** файл установщика. Docker-образы не тянутся, база панели не удаляется. Образы обновляет пункт **14**.

Сначала посмотрите версию в шапке справки: `bash remnawave-manager.sh --help` (строка «Корги Люси · Remnawave Manager …»).

### 1.1.0 или 1.2.0 — у вас нет `check-update`

Если `bash remnawave-manager.sh check-update` печатает **всю справку** и в шапке `1.1.0` / `1.2.0` — это нормально: команда появилась только в 1.3.0. В 1.1.0 уже есть `self-update`. На VDS выполните:

```bash
bash remnawave-manager.sh self-update
```

Скрипт скачает GitHub Latest, проверит `bash -n`, заменит файл (и `/usr/local/bin/remnawave-manager`, если CLI ставили) и перезапустится. После этого в шапке должно быть `1.3.0` или новее. `check-update` заработает только тогда.

Если `self-update` нет (1.0.0 / 25.2.x) или сеть к GitHub не открывается — скачайте Latest вручную, как в [Быстром старте](#быстрый-старт), и сверьте SHA256.

### Уже стоит 1.3.0 или новее

Меню само сверяется с GitHub Latest (не чаще раза в 6 часов) и предлагает установить. Или:

```bash
bash remnawave-manager.sh check-update
bash remnawave-manager.sh check-update --apply
```

То же: пункт **24** → **2**, или снова `self-update`. Не опрашивать GitHub: `--no-update-check`. Только проверка: пункт **24** → **3**.

Команду обновления скрипта запускайте на **обоих** VDS (панель и нода). Если CLI ставили пунктом **19**, после ручного `curl` выполните `bash remnawave-manager.sh install-script`.

### Когда файл уже новый

Remnawave обычно **переустанавливать не нужно**.

| Цель | Что дальше |
| --- | --- |
| HTTP 502 | пункт **7** / `repair` |
| Заново привязать CorgiLusi | пункт **4** / `protocols` (панель) |
| Добавить/снять gRPC, xHTTP, Hysteria2 | пункт **25** (панель), затем `node-transports apply` на ноде |
| Новые образы Remnawave | пункт **14** / `update` |

**Нельзя:** качать с `raw.githubusercontent.com/main`; снова пункт **1** «чтобы получить новый скрипт»; принимать пункт **14** за обновление этого файла; запускать PowerShell на Linux.

Полный текст: [docs/GUIDE.ru.md §10](docs/GUIDE.ru.md#10-как-правильно-обновить-этот-скрипт-до-latest).

---

## Меню

| № | Функция | Что делает |
| --- | --- | --- |
| 1 | Полная установка | Панель + нода на одном VDS, nginx SNI, Corgi, сертификаты, API |
| 2 | Только панель | Панель + подписка HTTPS; `EDGE_ADDRESS` сразу регистрирует ноду |
| 3 | Только нода | remnanode в host-сети, SNI Reality; `SECRET_KEY` из `credentials.txt` панели |
| 4 | Автопривязка протоколов | Отдельный профиль CorgiLusi на ноду, сквад CorgiLusi, без Default-Profile |
| 5 | Состояние | Контейнеры, nginx/fail2ban, systemd-таймеры |
| 6 | Диагностика | API панели, страница подписки, порты, UFW |
| 7 | Repair | Переписывает proxy-заголовки и SelfSteal без удаления Docker/БД |
| 8 | Логи | Журнал remnawave / remnanode / subscription-page |
| 9 | Up | `docker compose up` всех стеков |
| 10 | Down | `docker compose down` (данные сохраняются) |
| 11 | Перезапуск | Перезапуск всех compose-стеков Remnawave |
| 12 | Backup | Архив в `/var/backups/remnawave` |
| 13 | Restore | Восстановление из `.tgz` или `.age` |
| 14 | Обновление | Backup, pull **образов Remnawave**, проверка API |
| 15 | Удаление | Снимает сервисы и nginx vhost; backup’ы остаются |
| 16 | Ядро Xray | Свой бинарник или штатный из образа |
| 17 | Модули | CLI DigneZzZ, SelfSteal, WARP/Tor, NetBird, eGames |
| 18 | Скрытый вход | Cookie/query-затвор для `/auth/login` |
| 19 | Команда CLI | Копирует скрипт в `/usr/local/bin/remnawave-manager` |
| 20 | Конвертер | Необязательный JSON Rezzosoft (для привязки не нужен) |
| 21 | Авторство / справка | Авторы и полная справка CLI |
| 22 | Язык | Русский или English |
| 23 | Адреса | Панель / подписка / SNI и ссылка CorgiLusi |
| 24 | Обновления авторов | Свежие модули авторов; **обновление этого скрипта** |
| 25 | Транспорты ноды | Добавить или снять xHTTP, gRPC, Hysteria2 на уже установленной ноде |
| 0 | Выход | — |

---

## Режимы установки

| Команда | Что ставится |
| --- | --- |
| `install single` | Панель + нода на одном VDS |
| `install panel` | Только панель; к ней потом подключаются ноды |
| `install node` | Только нода на отдельном сервере (`SECRET_KEY` из `/opt/remnawave/credentials.txt` на панели) |

Два сервера:

```bash
# Панель (EDGE_ADDRESS — IP ноды, чтобы карточка Node создалась сразу)
bash remnawave-manager.sh --lang ru install panel --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com \
  EDGE_ADDRESS=203.0.113.20

# Нода (другой VDS)
bash remnawave-manager.sh --lang ru install node --yes \
  PANEL_IP=203.0.113.10 DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com NODE_SECRET_KEY='секрет_из_credentials.txt'
```

Подробности: [docs/GUIDE.ru.md](docs/GUIDE.ru.md#6-панель-и-нода-на-двух-серверах).

---

## Протоколы

По умолчанию включаются все. Привязка к панели — автоматически.

- Reality (VLESS TCP, SNI на 443, отпечаток хоста **firefox**)
- Hysteria2 UDP/443 в профиле Xray + sing-box UDP/8443
- VLESS gRPC + Reality TCP/8443
- VLESS xHTTP + Reality TCP/4443

Флаги: `--all-protocols` (то же, что по умолчанию), `--reality-only`, `--hysteria2`, `--grpc`, `--xhttp`.

На уже установленной системе **полная** перепривязка: `bash remnawave-manager.sh protocols` (синоним: `bind`) или пункт **4**.

Чтобы **добавить или снять** доп. протоколы на уже стоящей ноде (панель и нода могут быть на разных VDS), используйте **отдельный** пункт **25**:

```bash
# Панель
bash remnawave-manager.sh node-transports add grpc|xhttp|hysteria2|all
bash remnawave-manager.sh node-transports remove grpc|xhttp|hysteria2|all
bash remnawave-manager.sh node-transports reality-only

# Нода
bash remnawave-manager.sh node-transports apply
```

---

## Обслуживание

В шапке меню — живое состояние панели, подписки (`:3010`) и remnanode; после проверки GitHub — актуален ли сам скрипт.

При HTTP 502: пункт **7** или `bash remnawave-manager.sh repair`. Скрипты PowerShell на Linux VDS не запускайте.

CLI: `status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `urls`, `health`, `core-update`, `stealth`, `addon …`, `node-transports …`, `check-update`, `self-update`.

---

## Документация

| | English | Русский |
| --- | --- | --- |
| Полная инструкция | [docs/GUIDE.en.md](docs/GUIDE.en.md) | [docs/GUIDE.ru.md](docs/GUIDE.ru.md) |
| Журнал версий | [CHANGELOG.md](CHANGELOG.md) | [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md) |
| Контрольные суммы | [SHA256SUMS](SHA256SUMS) | то же |
| Авторство | [CREDITS.md](CREDITS.md) | то же |
| Релизы | [GitHub Latest](https://github.com/booarkz-cpu/remnawave-manager/releases/latest) | то же |
