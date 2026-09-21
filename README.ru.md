# Remnawave Manager

[English](README.md) · [Русский](README.ru.md)

**Полная инструкция:** [на русском](docs/GUIDE.ru.md) · [in English](docs/GUIDE.en.md)

Production-установщик [Remnawave](https://docs.rw) на Debian/Ubuntu. Интерактивное меню с описанием каждой функции. Язык: **русский** или **English**.

**Текущая версия:** `1.5.2`

**Лицензия:** [MIT](LICENSE) — можно использовать, копировать, менять и распространять с сохранением копирайта. Оригиналы, которые качает пункт **24**, остаются на условиях их авторов — [CREDITS.md](CREDITS.md).

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
- [Меню](#меню) — [полный разбор пунктов](#1-полная-установка) · [docs/MENU.ru.md](docs/MENU.ru.md)
- [Режимы установки](#режимы-установки)
- [Протоколы](#протоколы)
- [Обслуживание](#обслуживание)
- [Документация](#документация)
- [Лицензия](#лицензия)

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

Фиксированная 1.5.2 через jsDelivr (по желанию):

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.2/remnawave-manager.sh \
  -o remnawave-manager.sh
# sha256: 65a1a8ef96d427863c0fdad5fc765dee634f18562b34723a5e6a768acb9bc0ba
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

Скрипт скачает GitHub Latest, проверит `bash -n`, заменит файл (и `/usr/local/bin/remnawave-manager`, если CLI ставили) и перезапустится. После этого в шапке должно быть `1.4.0` или новее. `check-update` заработает только тогда.

Если `self-update` нет (1.0.0 / 25.2.x) или сеть к GitHub не открывается — скачайте Latest вручную, как в [Быстром старте](#быстрый-старт), и сверьте SHA256.

### Уже стоит 1.3.0 или новее

Меню само сверяется с GitHub Latest (не чаще раза в 6 часов) и предлагает установить. Или:

```bash
bash remnawave-manager.sh check-update
bash remnawave-manager.sh check-update --apply
bash remnawave-manager.sh --version
```

То же: пункт **26**, или снова `self-update`. Пункт **24** по-прежнему обновляет модули авторов (и оставляет ярлык на этот скрипт). Не опрашивать GitHub: `--no-update-check`. Только проверка: пункт **26** → **1**, или `check-update`. С 1.4.0 неизвестная команда больше не печатает всю справку.

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

Номера **1–27** не съезжают; **28–32** добавлены в 1.5.0. Без аргументов открывается это меню (`bash remnawave-manager.sh`). `sudo` не пишите.

Отдельные страницы (тот же текст): [docs/MENU.ru.md](docs/MENU.ru.md) · [English](docs/MENU.en.md).

| № | Функция | CLI |
| --- | --- | --- |
| [1](#1-полная-установка) | Полная установка | `install single` |
| [2](#2-только-панель) | Только панель | `install panel` |
| [3](#3-только-нода) | Только нода | `install node` |
| [4](#4-автопривязка-протоколов) | Автопривязка протоколов | `protocols` / `bind` |
| [5](#5-состояние) | Состояние | `status` |
| [6](#6-диагностика) | Диагностика | `doctor` |
| [7](#7-repair) | Repair | `repair` |
| [8](#8-логи) | Логи | `logs [контейнер]` |
| [9](#9-запуск-up) | Запуск (up) | `up` |
| [10](#10-стоп-down) | Стоп (down) | `down` |
| [11](#11-перезапуск) | Перезапуск | `restart` |
| [12](#12-backup) | Backup | `backup` |
| [13](#13-restore) | Restore | `restore ФАЙЛ` |
| [14](#14-обновление-образы-remnawave) | Обновление образов | `update` |
| [15](#15-удаление) | Удаление | `uninstall` |
| [16](#16-ядро-xray) | Ядро Xray | `core-update` |
| [17](#17-модули) | Модули | `addon …` |
| [18](#18-скрытый-вход) | Скрытый вход | `stealth` |
| [19](#19-команда-cli) | Команда CLI | `install-script` |
| [20](#20-конвертер) | Конвертер | (URL) |
| [21](#21-авторство--справка) | Авторство / справка | `--help` |
| [22](#22-язык) | Язык | `--lang ru\|en` |
| [23](#23-адреса) | Адреса | `urls` / `health` |
| [24](#24-обновления-авторов) | Обновления авторов | `community-update` |
| [25](#25-транспорты-ноды) | Транспорты ноды | `node-transports …` |
| [26](#26-этот-скрипт) | Этот скрипт | `self-update` / `check-update` |
| [27](#27-добавить-ноду) | Добавить ноду | `add-node` |
| [28](#28-пользователи) | Пользователи | `users …` |
| [29](#29-управление-нодами) | Управление нодами | `nodes …` |
| [30](#30-оповещения-и-удалённый-backup) | Оповещения и удалённый backup | `telegram` / `backup-remote` |
| [31](#31-сертификаты) | Сертификаты | `certs [renew]` |
| [32](#32-файрвол) | Файрвол | `firewall [IPv4]` |
| [0](#0-выход) | Выход | — |

Два разных обновления: пункт **26** меняет этот файл установщика; пункт **14** тянет Docker-образы Remnawave.

### 1. Полная установка

Ставит **панель + ноду на одном VDS**.

Спрашивает домены панели, подписки и Reality и email администратора, затем какие транспорты включить (по умолчанию: Reality + Hysteria2 + gRPC + xHTTP). Предпроверка: Ubuntu/Debian, DNS, свободны TCP 80/443, диск, Docker. Пакеты, `apt-get full-upgrade` (сам VDS не перезагружает), fail2ban, BBR, стеки Docker Compose, nginx SNI, Let’s Encrypt, пользователь CorgiLusi, отдельный config-профиль на ноду, inbound’ы, хосты, сквад **CorgiLusi**, удаление **Default-Profile**. Нода в `network_mode: host`; в карточке Node — gateway сети `remnawave-network`, не `127.0.0.1`. Пишет `/opt/remnawave/credentials.txt` и systemd-таймеры (backup, сертификаты, health).

Если Remnawave уже стоит, пункты 1–3 предлагают **repair**, **повторную привязку** или полную переустановку и не гоняют `apt full-upgrade` без нужды.

**Не** заменяет этот скрипт с GitHub (пункт **26**) и **не** тянет новые образы панели позже (пункт **14**).

### 2. Только панель

Панель + подписка HTTPS на этом VDS. remnanode здесь не ставится. `EDGE_ADDRESS` (публичный IP ноды) сразу создаёт карточку Node через API. **Node secret** из `/opt/remnawave/credentials.txt` перенесите на второй VDS и там пункт **3**.

### 3. Только нода

remnanode в host-сети + SNI Reality на втором VDS. Нужны `PANEL_IP`, домен Reality, email и `NODE_SECRET_KEY` из `credentials.txt` панели. UFW к IP панели (в том числе порт ноды 2222). Порты и сертификаты в `/dev/shm` под выбранные транспорты.

### 4. Автопривязка протоколов

**Полная пересборка** CorgiLusi: профили на каждую ноду, inbound’ы, хосты, сквад. Default-Profile удаляется. Хосты Reality — отпечаток uTLS **firefox**. Без флага протокола включает **все** транспорты. Точечно добавить/снять один транспорт — пункт **25**.

### 5. Состояние

Живое локальное здоровье: контейнеры Docker, nginx, fail2ban, systemd-таймеры. В шапке меню уже точки панели / `:3010` / remnanode; здесь полный вывод.

### 6. Диагностика

Только чтение: версия скрипта и GitHub Latest; ОС; Docker; `nginx -t`; API панели `/auth/status`; контейнер подписки и HTTP `:3010`; публичный HTTPS; срок Let’s Encrypt (предупреждение, если меньше 21 дня); слушатели TCP 80/443, UDP 443/8443 при Hysteria2, TCP 8443 при gRPC, TCP 4443 при xHTTP; `ss`; Connected нод через API; `docker ps`; таймеры; UFW.

### 7. Repair

Чинит **HTTP 502** панели или подписки **без** удаления Docker и PostgreSQL. Переписывает nginx (`X-Forwarded-For`, `X-Forwarded-Proto: https`), compose подписки, SelfSteal. Домены поднимает с диска, даже если в `manager.env` остался только язык.

### 8. Логи

`docker compose logs -f` для `remnawave`, `remnanode` или `remnawave-subscription-page` (имя спрашивает).

### 9. Запуск (up)

`docker compose up` всех найденных стеков Remnawave. Недостающие стеки не ставит.

### 10. Стоп (down)

`docker compose down`. **Тома и `/opt/remnawave` остаются.** Это не удаление.

### 11. Перезапуск

Перезапуск compose-стеков Remnawave. Образы не тянет.

### 12. Backup

Архив в `/var/backups/remnawave` (compose, env, nginx, credentials). Шифрование age — `/opt/remnawave/backup-age.key`.

### 13. Restore

Восстановление из `.tgz` или `.age`. Для age нужен ключ на диске. После сбоя пункта **14** скрипт сам может накатить последний снимок.

### 14. Обновление (образы Remnawave)

**Только Docker-образы**, не этот файл `.sh`. Порядок: backup → pull панели → ноды → подписки → Hysteria2 → проверка API → reload nginx. При сбое — попытка restore.

### 15. Удаление

Подтверждение `DELETE`. Останавливает compose, отключает таймеры remnawave, снимает nginx vhost. **Архивы в `/var/backups/remnawave` остаются.** Сам `rm -rf /opt/remnawave` не делает.

### 16. Ядро Xray

Свой/официальный бинарник Xray на ноде или штатный из образа.

### 17. Модули

Оригинальные помощники (авторство сохранено):

| Клавиша | Что |
| --- | --- |
| **a** | DigneZzZ remnawave CLI — помощник панели |
| **b** | DigneZzZ remnanode CLI — помощник ноды |
| **c** | Шаблоны SelfSteal |
| **d** | WARP / Tor (`wtm`) |
| **e** | NetBird |
| **f** | Установщик eGames reverse-proxy |

Привязка inbound’ов — этим менеджером (пункты **4** / **25**), не конвертером.

### 18. Скрытый вход

Затвор в стиле eGames: `/auth/login` отдаёт 404, пока нет секрета в query или cookie. Печатает `https://ПАНЕЛЬ/auth/login?КЛЮЧ=КЛЮЧ`.

### 19. Команда CLI

Копирует скрипт в `/usr/local/bin/remnawave-manager`. После ручного `curl` новой версии выполните пункт снова, чтобы PATH совпал с Latest.

### 20. Конвертер

Необязательный JSON Rezzosoft: <https://rezzosoft.ru/converter.html>. Для установки и привязки **не нужен**.

### 21. Авторство / справка

Автор Корги Люси, кредиты Rezzosoft / eGames / DigneZzZ и полная справка CLI.

### 22. Язык

**Русский** или **English**, в `RW_LANG` файла `manager.env`.

### 23. Адреса

Панель, подписка, SNI Reality и ссылка CorgiLusi. **Без паролей, JWT и секрета ноды**, пока не напишете **SHOW** — тогда логин панели печатается один раз и **не** попадает в `/var/log/remnawave-manager.log`. CLI: `admin-login`.

### 24. Обновления авторов

Качает **оригиналы** Rezzosoft / eGames / DigneZzZ в `/opt/remnawave-addons`. Подменю: (1) модули, (2) этот скрипт с GitHub Latest, (3) только проверка, (0) назад.

### 25. Транспорты ноды

Добавить или снять **xHTTP, gRPC, Hysteria2** на уже установленной ноде (в том числе на другом VDS). Добавление одного не включает остальные. Reality остаётся.

1. Нода: номер, UUID или **0** = все. **q** — главное меню.
2. Дальше: **[1]** Hysteria2 · **[2]** gRPC · **[3]** xHTTP · **[4]** все три · **[5–7]** снять один · **[8]** только Reality · **[9]** применить на **этом** сервере · **[0]** к **списку нод** · **[q]** главное меню.

На **панели** 1–8 меняют профиль и хосты через API и печатают команду для ноды: `bash remnawave-manager.sh node-transports apply`. На VDS **ноды** — **[9]** или эта команда.

### 26. Этот скрипт

GitHub **Latest этого установщика**, не образы Docker. (1) проверить Latest, (2) установить сейчас (`self-update`), (0) назад. С 1.3.0 главное меню само сверяется с Latest не чаще раза в 6 часов.

### 27. Добавить ноду

Регистрирует **ещё одну** ноду на уже работающей **панели** через API — без `apt full-upgrade` и без пункта **1**. Затем на новом VDS пункт **3** с Node secret из `credentials.txt`. Только с сервера панели.

### 28. Пользователи

Только панель. Список, создать (3–32 `A–Za-z0-9._-`), вкл/выкл, **ссылка подписки** (не пароль админа). Сквад как у CorgiLusi. CLI: `users list|create ИМЯ|enable UUID|disable UUID|sub UUID`.

### 29. Управление нодами

Выключить, включить, перезапустить **одну** ноду (`0` / `all` — все, только restart), сменить адрес. Выбор как в пункте 25. CLI: `nodes list|disable|enable|restart|address`.

### 30. Оповещения и удалённый backup

Telegram: токен + chat, тест. Healthcheck не чаще раза в час пишет, если API панели мёртв, сертификат < 21 дня или нода не Connected. rclone+age с VDS (02:00 или сразу). Токен в лог не попадает.

### 31. Сертификаты

Срок panel / sub / Reality. `certbot renew` сейчас, принудительно, копия в `/dev/shm` для Hysteria2. В шапке меню — ближайший срок.

### 32. Файрвол

Показать UFW, задать или снять **ADMIN_IP**, пересобрать правила. Снятие ADMIN_IP открывает SSH с любого IPv4.

### 0. Выход

Выход из меню (`0`, `q` или `Q`). Ничего не удаляет.

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

Чтобы **добавить или снять** доп. протоколы на уже стоящей ноде (панель и нода могут быть на разных VDS), используйте **отдельный** пункт **25**. Если нод несколько, меню спрашивает UUID (`0` = все):

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

CLI: `status`, `doctor`, `repair`, `backup`, `restore`, `update`, `up`, `down`, `restart`, `logs`, `urls`, `health`, `users`, `nodes`, `telegram`, `backup-remote`, `certs`, `firewall`, `admin-login`, `core-update`, `stealth`, `addon …`, `node-transports …`, `add-node`, `check-update`, `self-update`, `--version`.

---

## Документация

| | English | Русский |
| --- | --- | --- |
| Полная инструкция | [docs/GUIDE.en.md](docs/GUIDE.en.md) | [docs/GUIDE.ru.md](docs/GUIDE.ru.md) |
| Меню (каждый пункт) | [docs/MENU.en.md](docs/MENU.en.md) | [docs/MENU.ru.md](docs/MENU.ru.md) |
| Журнал версий | [CHANGELOG.md](CHANGELOG.md) | [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md) |
| Лицензия | [LICENSE](LICENSE) (MIT) | то же |
| Контрольные суммы | [SHA256SUMS](SHA256SUMS) | то же |
| Авторство | [CREDITS.md](CREDITS.md) | то же |
| Релизы | [GitHub Latest](https://github.com/booarkz-cpu/remnawave-manager/releases/latest) | то же |

---

## Лицензия

**MIT.** Copyright (c) 2026 Корги Люси (Corgi Lusi). Полный текст: [LICENSE](LICENSE).

Можно использовать, копировать, изменять, публиковать, распространять, сублицензировать и продавать копии этого установщика, если копирайт и текст разрешения сохраняются во всех копиях.

Лицензия покрывает **этот репозиторий** (`remnawave-manager.sh` и документацию). Она совместима с MIT у [DigneZzZ/remnawave-scripts](https://github.com/DigneZzZ/remnawave-scripts) и [eGamesAPI/remnawave-reverse-proxy](https://github.com/eGamesAPI/remnawave-reverse-proxy). Пункт **24** кладёт оригиналы авторов в `/opt/remnawave-addons` — они остаются на **их** условиях. У Rezzosoft в публичном репозитории нет SPDX: мы его не перелицензируем, авторство сохраняем, конвертер — необязательная ссылка.

Гарантий нет. Секреты из `credentials.txt` не публикуйте. См. [SECURITY.md](SECURITY.md).
