# Remnawave Manager — инструкция на русском

[English](GUIDE.en.md) · [Русский](GUIDE.ru.md) · [README](../README.ru.md)

Установщик и повседневный менеджер [Remnawave](https://docs.rw) на Debian/Ubuntu. Автор: **Корги Люси (Corgi Lusi)**. Текущая версия скрипта: **1.5.6**.

Это полная инструкция. На GitHub в README — **полный разбор каждого пункта меню** на русском и английском. Журнал обновлений по версиям: [INSTALLATION_RU.md](INSTALLATION_RU.md), [CHANGELOG.md](../CHANGELOG.md) (English) · [CHANGELOG.ru.md](../CHANGELOG.ru.md) (русский). Безопасность: [SECURITY.md](../SECURITY.md) · [SECURITY.ru.md](../SECURITY.ru.md). Лицензия: [MIT](../LICENSE).

Есть **два разных** обновления. Их нельзя путать:

| Что | Команда / меню | Что меняется |
| --- | --- | --- |
| **Этот скрипт** (`remnawave-manager.sh`) | `check-update`, `self-update`, пункт **26** | Файл установщика на диске |
| **Remnawave** (образы панели, ноды, подписки) | `update`, пункт **14** | Docker-образы; данные панели сохраняются |

---

## Содержание

1. [Что делает скрипт](#1-что-делает-скрипт)
2. [Требования](#2-требования)
3. [Скачать и проверить](#3-скачать-и-проверить)
4. [Первый запуск](#4-первый-запуск)
5. [Установка на один VDS](#5-установка-на-один-vds)
6. [Панель и нода на двух серверах](#6-панель-и-нода-на-двух-серверах)
7. [После установки](#7-после-установки)
8. [Меню](#8-меню) — полный каталог: [MENU.ru.md](MENU.ru.md)
9. [Транспорты (Reality, gRPC, xHTTP, Hysteria2)](#9-транспорты-reality-grpc-xhttp-hysteria2)
10. [Как правильно обновить этот скрипт до Latest](#10-как-правильно-обновить-этот-скрипт-до-latest)
11. [Как обновить образы Remnawave](#11-как-обновить-образы-remnawave)
12. [Repair, 502, диагностика](#12-repair-502-диагностика)
13. [Backup и restore](#13-backup-и-restore)
14. [Справка CLI](#14-справка-cli)
15. [Файлы на диске](#15-файлы-на-диске)
16. [Модули и авторство](#16-модули-и-авторство)
17. [Если что-то не работает](#17-если-что-то-не-работает)
18. [Чего не делать](#18-чего-не-делать)

---

## 1. Что делает скрипт

Ставит nginx (SNI + HTTPS), стеки Docker Compose, сертификаты Let’s Encrypt, UFW и маскировочный сайт Corgi для Reality. Затем через **API** Remnawave создаёт:

- config-профиль на каждую ноду с именем **CorgiLusi** / `CorgiLusi-…`
- inbound’ы выбранных транспортов
- карточки нод и хосты (отпечаток uTLS **firefox**, где Reality его требует)
- внутренний сквад **CorgiLusi**
- пользователя **CorgiLusi** и URL подписки

**Default-Profile** (и сквады AUTO / Default) удаляются после привязки. Inbound’ы в UI панели править не нужно. Конвертер Rezzosoft для привязки не требуется.

В скрипт входят функции (авторство исходников сохранено — [CREDITS.md](../CREDITS.md)):

- Rezzosoft KVN — Hysteria2 / gRPC / xHTTP на ноде
- eGamesAPI — панель и нода на разных VDS, скрытый вход, SelfSteal
- DigneZzZ — CLI, бэкапы, ядро Xray, WARP/Tor, NetBird

---

## 2. Требования

- VDS Debian или Ubuntu (проверено на Ubuntu 24.04)
- Публичный IPv4
- DNS **A**-записи:
  - домен панели → VDS панели
  - домен подписки → VDS панели
  - домен SNI Reality → VDS ноды (на одном сервере — тот же VDS)
- Свободные порты 80/tcp и 443/tcp для nginx / ACME
- Скрипты PowerShell на Linux VDS не запускайте

Удобно три имени в одной зоне, например `pst.example.com`, `sb.example.com`, `blog.example.com`.

---

## 3. Скачать и проверить

Берите **GitHub Latest**, не `raw.githubusercontent.com/main`.

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

Две суммы должны совпасть. Latest: <https://github.com/booarkz-cpu/remnawave-manager/releases/latest>

Фиксированная копия (пример для 1.5.6):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.6/remnawave-manager.sh \
  -o remnawave-manager.sh
sha256sum remnawave-manager.sh
# 1.5.6: e27712e9308fbcd8fca62dae9c2549c1cd994068bac6662f8e9a173387e80c23
```

Все суммы версий — в [SHA256SUMS](../SHA256SUMS).

---

## 4. Первый запуск

```bash
bash remnawave-manager.sh
```

Префикс **`sudo` писать не нужно**. Если вы не root, скрипт сам перезапустится через sudo. `--help` пароль не спрашивает.

Без аргументов **сначала язык** (English / Русский; Enter оставляет текущий `RW_LANG`), затем нумерованное меню.

Пропустить выбор: `--lang ru|en` (пишется в `/opt/remnawave/manager.env`, на ноде без панели — в env edge). Внутри сессии — пункт **22**.

```bash
bash remnawave-manager.sh --lang ru
bash remnawave-manager.sh --lang en
```

Позже: пункт **22**. Справка:

```bash
bash remnawave-manager.sh --help
```

По желанию скопировать в `PATH` (пункт **19**):

```bash
bash remnawave-manager.sh install-script
# дальше: remnawave-manager
```

С **1.3.0** меню само сверяется с GitHub Latest (не чаще раза в 6 часов). Если есть новее — предлагает установить. Отключить: `--no-update-check`.

---

## 5. Установка на один VDS

Пункт **1** или:

```bash
bash remnawave-manager.sh --lang ru install single --yes \
  DOMAIN_PANEL=pst.example.com \
  DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com
```

Пробный запуск без установки:

```bash
bash remnawave-manager.sh install single --dry-run --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com
```

Во время `install` идёт `apt-get full-upgrade`. VDS сам не перезагружается. Если появится `/var/run/reboot-required`, перезагрузите сервер после установки.

Панель в Docker. Нода — `network_mode: host`. В карточке Node пишется gateway сети `remnawave-network`, **не** `127.0.0.1`.

Если Remnawave уже стоит, пункты 1–3 предлагают **repair**, **повторную привязку** или полную переустановку и не гоняют `apt full-upgrade` без нужды.

---

## 6. Панель и нода на двух серверах

**Сначала панель** (пункт **2**). `EDGE_ADDRESS` — публичный IP ноды, чтобы карточка Node появилась сразу:

```bash
bash remnawave-manager.sh --lang ru install panel --yes \
  DOMAIN_PANEL=pst.example.com DOMAIN_SUB=sb.example.com \
  DOMAIN_REALITY=blog.example.com ADMIN_EMAIL=admin@example.com \
  EDGE_ADDRESS=203.0.113.20
```

Скопируйте **Node secret** из `/opt/remnawave/credentials.txt` на панели (в GitHub, issue и чаты не публикуйте).

**Нода** на втором VDS (пункт **3**; `install node` = `install edge`):

```bash
bash remnawave-manager.sh --lang ru install node --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=blog.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='секрет_из_credentials.txt'
```

Имя Reality должно смотреть на **IP ноды**. Имена панели и подписки — на **IP панели**.

Если панель ставили без `EDGE_ADDRESS`, после запуска ноды на панели выполните пункт **4** / `protocols`.

---

## 7. После установки

Пункт **23** печатает публичные адреса без паролей.

| Что | Где |
| --- | --- |
| Панель | `https://DOMAIN_PANEL` |
| Страница подписки | `https://DOMAIN_SUB` |
| SNI Reality (сайт о корги) | `https://DOMAIN_REALITY` |
| Админ / API-токен / секрет ноды | `/opt/remnawave/credentials.txt` |
| Флаги менеджера | `/opt/remnawave/manager.env` (только нода: `/opt/remnawave-edge/manager.env`) |
| Журнал установки | `/var/log/remnawave-manager.log` |

После сохранения секретов удалите `credentials.txt`.

Backend панели требует заголовки reverse-proxy (`X-Forwarded-For` и `X-Forwarded-Proto: https`). Установщик прописывает их в nginx. Не открывайте `:3000` в интернет в обход nginx.

---

## 8. Меню

Номера **1–27** не съезжают; **28–32** добавлены в 1.5.0. **Полный функционал каждого пункта:** [MENU.ru.md](MENU.ru.md) · [English](MENU.en.md) · также в GitHub [README.ru.md](../README.ru.md#меню).

| № | Функция | Что делает |
| --- | --- | --- |
| 1 | Полная установка | Панель + нода на одном VDS |
| 2 | Только панель | Панель + подписка HTTPS |
| 3 | Только нода | remnanode + SNI Reality |
| 4 | Автопривязка протоколов | Профили CorgiLusi, сквад, хосты; удаление Default-Profile |
| 5 | Состояние | Контейнеры, nginx, fail2ban, таймеры |
| 6 | Диагностика | API, `:3010`, публичный HTTPS, сертификаты, UDP/TCP, Connected нод, UFW |
| 7 | Repair | Исправить nginx и 502 подписки; Docker/БД не трогает |
| 8 | Логи | remnawave / remnanode / subscription-page |
| 9 | Up | `docker compose up` всех стеков |
| 10 | Down | `docker compose down` (данные сохраняются) |
| 11 | Перезапуск | Перезапуск compose-стеков Remnawave |
| 12 | Backup | Архив в `/var/backups/remnawave` |
| 13 | Restore | Восстановление из `.tgz` или `.age` |
| 14 | Обновление | Backup + pull **образов Remnawave** (не этого скрипта) |
| 15 | Удаление | Сервисы и nginx vhost; backup остаётся |
| 16 | Ядро Xray | Свой бинарник или штатный из образа |
| 17 | Модули | CLI DigneZzZ, SelfSteal, WARP/Tor, NetBird, eGames |
| 18 | Скрытый вход | Прячет `/auth/login` за секретом |
| 19 | Команда CLI | Копирует в `/usr/local/bin/remnawave-manager` |
| 20 | Конвертер | Необязательный JSON Rezzosoft — для привязки не нужен |
| 21 | Авторство / справка | Авторы и справка CLI |
| 22 | Язык | Русский или English |
| 23 | Адреса | Панель / подписка / SNI / CorgiLusi; SHOW — логин панели один раз |
| 24 | Обновления авторов | Модули upstream (этот скрипт: пункт **26**) |
| 25 | Транспорты ноды | Добавить или снять xHTTP, gRPC, Hysteria2; панель печатает apply для ноды |
| 26 | Этот скрипт | Проверить / поставить GitHub Latest этого установщика |
| 27 | Добавить ноду | Зарегистрировать ещё одну ноду через API — без обновления ОС и без пункта 1 |
| 28 | Пользователи | Список / создать / вкл / выкл / ссылка подписки |
| 29 | Управление нодами | Выкл, вкл, перезапуск одной ноды, смена адреса |
| 30 | Оповещения и удалённый backup | Telegram; rclone+age с VDS |
| 31 | Сертификаты | Срок, обновить сейчас, `/dev/shm` на ноде |
| 32 | Файрвол | ADMIN_IP, пересборка UFW |
| 0 | Выход | — |

---

## 9. Транспорты (Reality, gRPC, xHTTP, Hysteria2)

По умолчанию при установке включаются **все четыре**.

| Транспорт | Порт | Заметки |
| --- | --- | --- |
| VLESS Reality TCP | 443 | SNI = домен Reality; отпечаток хоста firefox |
| Hysteria2 | UDP/443 (+ sing-box UDP/8443) | Отпечаток uTLS не ставится |
| VLESS gRPC Reality | TCP/8443 | path `/grpc`, отпечаток firefox |
| VLESS xHTTP Reality | TCP/4443 | path `/xhttp`, отпечаток firefox |

Флаги установки: `--all-protocols` (по умолчанию), `--reality-only`, `--hysteria2`, `--grpc`, `--xhttp`.

**Полная перепривязка** всех профилей (пункт **4** / `protocols` / `bind`) — после установки или когда нужно заново собрать CorgiLusi. Без флага протокола эта команда включает **все** транспорты.

**Добавить или снять** доп. протоколы на уже установленной ноде, в том числе на другом VDS — **отдельный** пункт **25**. Добавление одного транспорта не сбрасывает остальные. Нода: номер, UUID или `0` = все. После выбора `[0]` — снова список нод, `q` — главное меню. На VDS **только панели** пункты 1–8 печатают команду для ноды: `bash remnawave-manager.sh node-transports apply`.

На **панели**:

```bash
bash remnawave-manager.sh node-transports add grpc
bash remnawave-manager.sh node-transports add xhttp
bash remnawave-manager.sh node-transports add hysteria2
bash remnawave-manager.sh node-transports add all
bash remnawave-manager.sh node-transports remove grpc
bash remnawave-manager.sh node-transports remove xhttp
bash remnawave-manager.sh node-transports remove hysteria2
bash remnawave-manager.sh node-transports reality-only
```

На **ноде** (UFW, сертификаты в `/dev/shm`, sing-box Hysteria2):

```bash
bash remnawave-manager.sh node-transports apply
```

---

## 10. Как правильно обновить этот скрипт до Latest

Этот раздел обновляет **только** `remnawave-manager.sh` (и `/usr/local/bin/remnawave-manager`, если ставили CLI). Он **не** тянет Docker-образы и **не** удаляет базу панели.

Сначала версия в шапке: `bash remnawave-manager.sh --help`.

### Способ A — 1.1.0 или 1.2.0 (`check-update` печатает справку)

Команды `check-update` в этих версиях **нет**. Неизвестная команда печатает полный `--help` — это не ошибка сети. В 1.1.0 уже есть `self-update`:

```bash
bash remnawave-manager.sh self-update
```

После замены в шапке должно быть `1.4.0` или новее. Тогда заработают `check-update` и автопроверка в меню.

### Способ B — уже 1.3.0 или новее

1. Откройте меню: `bash remnawave-manager.sh`
2. Если GitHub Latest новее — ответьте **Y**.
3. Или:

```bash
bash remnawave-manager.sh check-update
bash remnawave-manager.sh check-update --apply
```

То же: пункт **26**, или снова `self-update`. С 1.4.0 неизвестная команда печатает короткий текст, а не всю справку.

Не опрашивать GitHub при открытии меню:

```bash
bash remnawave-manager.sh --no-update-check
```

Время проверки — `LAST_UPDATE_CHECK_AT` / `LAST_REMOTE_VERSION` в `manager.env` (кэш 6 часов). Пункт **26** → **1** — только проверка, без скачивания.

### Способ C — нет `self-update` (1.0.0 / 25.2.x) или GitHub не открывается

Скачайте Latest вручную и сверьте хеш:

```bash
cd ~
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

Если суммы **не** совпали — **не запускайте** файл. Если совпали:

```bash
grep VERSION= remnawave-manager.sh | head -1
bash remnawave-manager.sh --lang ru
```

Если раньше включали пункт **19**, обновите копию CLI из нового файла:

```bash
bash remnawave-manager.sh install-script
```

Так нужно сделать на **каждом** VDS, где лежит менеджер: и на панели, и на ноде.

### Когда файл скрипта уже новый

Remnawave обычно **переустанавливать не нужно**.

| Цель | Что дальше |
| --- | --- |
| 502 панели или подписки | пункт **7** / `repair` |
| HTTP **500** на `https://SUB/` (питомник) | обновить до **1.5.6**, затем `sub-stub refresh` или открыть меню (переписывает vhost 1.5.5 с `alias`) |
| Новая привязка / CorgiLusi / отпечаток firefox | пункт **4** / `protocols` на **панели** |
| Добавить/снять gRPC, xHTTP, Hysteria2 | пункт **25** / `node-transports` (панель, затем `apply` на ноде) |
| Новые образы контейнеров Remnawave | пункт **14** / `update` (это не обновление скрипта) |

### Как обновлять скрипт неправильно

- `raw.githubusercontent.com/.../main/remnawave-manager.sh` — это не релиз, файл может быть неготовым
- Снова пункт **1** «чтобы получить новый скрипт» — это переустановка, а не обновление файла
- Пункт **14** в ожидании, что сменится этот файл с GitHub — **14** тянет только Docker-образы
- PowerShell `Invoke-WebRequest` на Linux VDS
- Префикс `sudo` (скрипт поднимает root сам)

---

## 11. Как обновить образы Remnawave

Пункт **14** или:

```bash
bash remnawave-manager.sh update
```

Порядок: backup → pull панели → ноды → подписки → Hysteria2 → проверка API панели → reload nginx. Это отдельно от [раздела 10](#10-как-правильно-обновить-этот-скрипт-до-latest).

---

## 12. Repair, 502, диагностика

Если панель или страница подписки отвечает **502**, в nginx скорее всего нет `X-Forwarded-For` / `X-Forwarded-Proto: https`, либо не жив контейнер `remnawave-subscription-page`.

```bash
bash remnawave-manager.sh repair   # пункт 7
bash remnawave-manager.sh doctor
bash remnawave-manager.sh urls
```

Repair переписывает nginx и compose подписки **без** удаления PostgreSQL. Если в `manager.env` остался только язык, домены поднимаются из `.env`, `credentials.txt`, nginx и Let’s Encrypt.

Логи:

```bash
tail -100 /var/log/remnawave-manager.log
bash remnawave-manager.sh logs remnawave
bash remnawave-manager.sh logs remnawave-subscription-page
bash remnawave-manager.sh logs remnanode
```

---

## 13. Backup и restore

```bash
bash remnawave-manager.sh backup
bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

Для архивов `.age` нужен `/opt/remnawave/backup-age.key`. Uninstall (пункт **15**) снимает сервисы и vhost; backup’ы остаются.

---

## 14. Справка CLI

```text
bash remnawave-manager.sh                         # меню
bash remnawave-manager.sh --lang en|ru
bash remnawave-manager.sh --help
bash remnawave-manager.sh --version
bash remnawave-manager.sh --no-update-check

bash remnawave-manager.sh install single|panel|node [--yes] [--dry-run]
bash remnawave-manager.sh protocols | bind
bash remnawave-manager.sh add-node
bash remnawave-manager.sh node-transports add|remove grpc|xhttp|hysteria2|all [uuid]
bash remnawave-manager.sh node-transports apply | reality-only

bash remnawave-manager.sh check-update [--apply]
bash remnawave-manager.sh self-update
bash remnawave-manager.sh community-update

bash remnawave-manager.sh status | doctor | repair | urls
bash remnawave-manager.sh users list
bash remnawave-manager.sh users create ИМЯ [ДНИ|ГГГГ-ММ-ДД] [ГБ|512M|10G] [УСТРОЙСТВА]
bash remnawave-manager.sh users enable|disable|sub UUID_ИЛИ_ИМЯ
bash remnawave-manager.sh nodes list|disable|enable|restart|address
bash remnawave-manager.sh telegram enable|disable|test
bash remnawave-manager.sh backup-remote [rclone:path]
bash remnawave-manager.sh certs [renew|force]
bash remnawave-manager.sh firewall [IPv4]
bash remnawave-manager.sh sub-stub on|off|status|refresh
bash remnawave-manager.sh admin-login SHOW
bash remnawave-manager.sh backup | restore FILE | update
bash remnawave-manager.sh up | down | restart | logs [контейнер]
bash remnawave-manager.sh stealth | install-script
bash remnawave-manager.sh addon remnawave|remnanode|selfsteal|wtm|netbird|egames
```

`--yes` требует домены/email (и секрет ноды в режиме node) в командной строке.

---

## 15. Файлы на диске

| Путь | Назначение |
| --- | --- |
| `/opt/remnawave/` | Compose панели, `.env`, `manager.env` |
| `/opt/remnawave/subscription/` | Страница подписки |
| `/opt/remnawave/node/` | Нода на одном VDS |
| `/opt/remnawave-edge/` | VDS только с нодой |
| `/opt/remnawave/hysteria2/` | sing-box Hysteria2 |
| `/opt/remnawave/credentials.txt` | Админ, токены, секрет ноды |
| `/opt/remnawave-addons/` | Скачанные модули авторов (пункт 24) |
| `/var/backups/remnawave/` | Backup |
| `/usr/local/sbin/remnawave-health-notify.sh` | Telegram из 5-минутного healthcheck (пункт **30**) |
| `/usr/local/bin/remnawave-manager` | Необязательная копия CLI |
| `/var/www/sub-site/` | Заглушка питомника корги на корне домена SUB (пункт **33**) |

Не публикуйте API-токены, `SECRET_KEY`, пароль PostgreSQL и `credentials.txt`. См. [SECURITY.ru.md](../SECURITY.ru.md) и [SECURITY.md](../SECURITY.md).

---

## 16. Модули и авторство

Пункт **24** / `community-update` скачивает **оригиналы** Rezzosoft / eGames / DigneZzZ в `/opt/remnawave-addons` и пишет авторов в `AUTHORS.txt`. Чужой код за свой не выдаём.

Необязательный конвертер (для привязки не нужен): <https://rezzosoft.ru/converter.html>

---

## 17. Если что-то не работает

| Симптом | Что делать |
| --- | --- |
| Панель или подписка **502** | `repair`; `docker ps` — есть ли `remnawave-subscription-page` |
| `repair` просит DOMAIN_* | Введите имена panel / sub / Reality; 1.3.x поднимает их и с диска |
| Нода не Connected | UFW 2222 только с IP панели; `SECRET_KEY` как в `credentials.txt`; DNS Reality → нода |
| Доп. протокол не работает | Пункт **25** на панели, затем `node-transports apply` на ноде |
| `check-update` печатает всю справку `1.1.0` | Это старый скрипт. Выполните `bash remnawave-manager.sh self-update` (с 1.4.0 неизвестная команда — короткий текст) |
| Меню не видит новый скрипт | пункт **26**, `self-update` или `check-update --apply` (с 1.3.0); кэш 6 часов |
| Хеш не совпал | Удалите файл, скачайте Latest снова, не запускайте |
| `"-":0: bad minute` на старом 25.2.2 | Обновите **скрипт** (раздел 10), затем `protocols` — сертификаты Hysteria идут через systemd, не crontab |
| Корень SUB по-прежнему страница подписки | пункт **33** → 2 или `sub-stub on`, затем `repair` |
| `https://SUB/` отвечает **500 Internal Server Error** (nginx 1.24) | ошибка 1.5.5 (`alias` на `location = /`). `self-update` до 1.5.6, затем `sub-stub refresh` |
| На заглушке только SVG, без фото | `sub-stub refresh` (нужен `sub-stub-photos.tgz` из GitHub Latest) |

---

## 18. Чего не делать

- Не пишите `sudo` перед командой
- Не запускайте PowerShell на VDS
- Не привязывайте inbound’ы руками в панели, если установщик уже это сделал
- Не указывайте ноде адрес `127.0.0.1` на одном VDS
- Не принимайте пункт **14** за обновление этого скрипта с GitHub
- Не публикуйте `credentials.txt`

Версии: [CHANGELOG.md](../CHANGELOG.md) · [CHANGELOG.ru.md](../CHANGELOG.ru.md), [релизы](https://github.com/booarkz-cpu/remnawave-manager/releases).
