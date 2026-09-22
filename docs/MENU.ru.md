# Меню — полный функционал каждого пункта

[English](MENU.en.md) · [Русский](MENU.ru.md) · [README](../README.ru.md) · [Инструкция](GUIDE.ru.md)

Меню без аргументов: `bash remnawave-manager.sh`. **Сначала язык** (Enter оставляет текущий); пункт **22** переключает позже. Префикс `sudo` не пишите. Номера **1–27** не съезжают; **28–32** добавлены в 1.5.0; **33** — заглушка корги на домене SUB (1.5.5); **34** — личный кабинет (1.6.0). **0** / `q` — выход.

Два обновления, которые путают:

| Цель | Пункт | CLI |
| --- | --- | --- |
| Новый файл установщика | **26** | `self-update` / `check-update --apply` |
| Новые Docker-образы Remnawave | **14** | `update` |

---

## 1. Полная установка

Ставит **панель + ноду на одном VDS**.

Спрашивает домены панели, подписки и Reality и email администратора, затем какие транспорты включить (по умолчанию: Reality + Hysteria2 + gRPC + xHTTP). Предпроверка: Ubuntu/Debian, DNS, свободны TCP 80/443, диск, Docker. Пакеты, `apt-get full-upgrade` (сам VDS не перезагружает), fail2ban, BBR, стеки Docker Compose, nginx SNI, Let’s Encrypt, пользователь CorgiLusi, отдельный config-профиль на ноду, inbound’ы, хосты, сквад **CorgiLusi**, удаление **Default-Profile**. Нода в `network_mode: host`; в карточке Node — gateway сети `remnawave-network`, не `127.0.0.1`. Пишет `/opt/remnawave/credentials.txt` и systemd-таймеры (backup, сертификаты, health).

Если Remnawave уже стоит, пункты 1–3 предлагают **repair**, **повторную привязку** или полную переустановку и не гоняют `apt full-upgrade` без нужды.

**Не** заменяет этот скрипт с GitHub (это пункт **26**) и **не** тянет новые образы панели позже (это пункт **14**).

CLI: `bash remnawave-manager.sh install single`

---

## 2. Только панель

Панель + подписка HTTPS на этом VDS. remnanode здесь не ставится.

`EDGE_ADDRESS` (публичный IP ноды) сразу создаёт карточку Node через API. **Node secret** из `/opt/remnawave/credentials.txt` перенесите на второй VDS и там пункт **3**.

CLI: `bash remnawave-manager.sh install panel`

---

## 3. Только нода

remnanode в host-сети + SNI Reality на втором VDS. Нужны `PANEL_IP`, домен Reality, email и `NODE_SECRET_KEY` из `credentials.txt` панели. UFW к IP панели (в том числе порт ноды 2222). Порты и сертификаты в `/dev/shm` под выбранные транспорты.

CLI: `bash remnawave-manager.sh install node` (то же, что `install edge`)

---

## 4. Автопривязка протоколов

**Полная пересборка** CorgiLusi: профили на каждую ноду, inbound’ы, хосты, сквад. Default-Profile удаляется. Хосты Reality — отпечаток uTLS **firefox**. Без флага протокола команда включает **все** транспорты.

Нужна после установки, после обновления скрипта, которое меняет привязку, или если панель правили руками. Точечно добавить/снять один транспорт — пункт **25**.

CLI: `bash remnawave-manager.sh protocols` (синоним: `bind`)

---

## 5. Состояние

Живое локальное здоровье: контейнеры Docker, nginx, fail2ban, systemd-таймеры. В шапке меню уже точки панели / `:3010` / remnanode; здесь полный вывод.

CLI: `bash remnawave-manager.sh status`

---

## 6. Диагностика

Только чтение, ничего не меняет:

- версия этого скрипта и GitHub Latest
- ОС, Docker, `nginx -t`
- API панели `/auth/status`
- контейнер `remnawave-subscription-page` и HTTP на `:3010`
- публичный HTTPS
- срок Let’s Encrypt (предупреждение, если меньше 21 дня)
- слушатели: TCP 80/443; UDP 443/8443 при Hysteria2; TCP 8443 при gRPC; TCP 4443 при xHTTP
- `ss` по типичным портам
- каждая нода **Connected** / нет через API (на VDS «только нода» списка нет)
- `docker ps`, таймеры remnawave, UFW

CLI: `bash remnawave-manager.sh doctor`

---

## 7. Repair

Чинит **HTTP 502** панели или подписки **без** удаления Docker и PostgreSQL. Переписывает nginx (`X-Forwarded-For`, `X-Forwarded-Proto: https`), compose подписки, SelfSteal. Домены `DOMAIN_*` поднимает с диска (`.env`, `credentials.txt`, nginx, Let’s Encrypt), даже если в `manager.env` остался только язык.

CLI: `bash remnawave-manager.sh repair`

---

## 8. Логи

Спрашивает контейнер и показывает `docker compose logs -f`. Обычно: `remnawave`, `remnanode`, `remnawave-subscription-page`. Пустой ввод — журнал по умолчанию.

CLI: `bash remnawave-manager.sh logs remnawave`

---

## 9. Запуск (up)

`docker compose up` всех найденных стеков Remnawave: панель, нода (single или edge), подписка, Hysteria2, мониторинг. Недостающие стеки не ставит.

CLI: `bash remnawave-manager.sh up`

---

## 10. Стоп (down)

`docker compose down` этих стеков. **Тома и `/opt/remnawave` остаются.** Это не удаление.

CLI: `bash remnawave-manager.sh down`

---

## 11. Перезапуск

Перезапускает все compose-стеки Remnawave (панель, нода, подписка, Hysteria2). Образы не тянет.

CLI: `bash remnawave-manager.sh restart`

---

## 12. Backup

Архив в `/var/backups/remnawave` (compose, env, фрагменты nginx, credentials). Шифрование age — ключ `/opt/remnawave/backup-age.key`.

CLI: `bash remnawave-manager.sh backup`

---

## 13. Restore

Путь к `.tgz` или `.age` и восстановление. Для age на диске должен быть закрытый ключ. После сбоя пункта **14** скрипт сам может накатить последний снимок.

CLI: `bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz`

---

## 14. Обновление (образы Remnawave)

**Только Docker-образы**, не этот файл `.sh`.

Порядок: backup → pull панели → ноды → подписки → Hysteria2 → проверка API → reload nginx. Если шаг падает — попытка restore последнего backup.

CLI: `bash remnawave-manager.sh update`

---

## 15. Удаление

Подтверждение строкой `DELETE`. Останавливает compose, отключает systemd-таймеры remnawave, снимает nginx vhost и вспомогательные скрипты. **Архивы в `/var/backups/remnawave` остаются.** Сам `rm -rf /opt/remnawave` не делает.

CLI: `bash remnawave-manager.sh uninstall` (с `--yes` без запроса `DELETE`)

---

## 16. Ядро Xray

Свой/официальный бинарник Xray на ноде или возврат штатного из образа. Путь: `/opt/remnawave/node` (или edge).

CLI: `bash remnawave-manager.sh core-update`

---

## 17. Модули

Запуск **оригинальных** помощников (авторство сохранено). Подменю:

| Клавиша | Что |
| --- | --- |
| **a** | DigneZzZ remnawave CLI — помощник панели |
| **b** | DigneZzZ remnanode CLI — помощник ноды |
| **c** | Шаблоны SelfSteal |
| **d** | WARP / Tor (`wtm`) |
| **e** | NetBird |
| **f** | Установщик eGames reverse-proxy |

Это необязательные дополнения. Привязка inbound’ов — этим менеджером (пункты **4** / **25**), не конвертером.

CLI: `bash remnawave-manager.sh addon remnawave|remnanode|selfsteal|wtm|netbird|egames`

---

## 18. Скрытый вход

Затвор в стиле eGames: `/auth/login` отдаёт 404, пока нет секрета в query или cookie, затем ставит HttpOnly cookie. Печатает `https://ПАНЕЛЬ/auth/login?КЛЮЧ=КЛЮЧ`. Нужен уже установленный nginx vhost панели.

CLI: `bash remnawave-manager.sh stealth`

---

## 19. Команда CLI

Копирует этот файл в `/usr/local/bin/remnawave-manager`, дальше можно `remnawave-manager` без пути. После ручного `curl` новой версии выполните пункт снова (или `install-script`), чтобы PATH совпал с GitHub Latest.

CLI: `bash remnawave-manager.sh install-script`

---

## 20. Конвертер

Печатает / открывает необязательный JSON-конвертер Rezzosoft: <https://rezzosoft.ru/converter.html>. Для установки и привязки **не нужен**. Профили, хосты и сквад создаёт API панели.

---

## 21. Авторство / справка

Автор Корги Люси, кредиты Rezzosoft / eGames / DigneZzZ и полная справка CLI. То же, что `bash remnawave-manager.sh --help`, плюс блок авторства.

---

## 22. Язык

Спрашивается **при каждом запуске меню** (до пунктов 1–32). **Русский** или **English**. Enter оставляет текущий язык. Пишется в `RW_LANG` в `/opt/remnawave/manager.env` (на ноде без панели — env edge). Этот пункт переключает язык снова, не выходя из сессии.

Пропустить выбор при старте: `bash remnawave-manager.sh --lang ru|en`

---

## 23. Адреса

Панель, подписка, SNI Reality и ссылка пользователя CorgiLusi. **Без паролей, JWT и секрета ноды**, пока не напишете **SHOW**. Тогда логин панели печатается **один раз** и **не** попадает в `/var/log/remnawave-manager.log`. Любой другой ответ — отмена.

CLI: `bash remnawave-manager.sh urls` · проверка снаружи: `health` · `bash remnawave-manager.sh admin-login SHOW`

---

## 24. Обновления авторов

Качает **оригиналы** Rezzosoft / eGames / DigneZzZ в `/opt/remnawave-addons` и пишет `AUTHORS.txt`. Этот менеджер чужой код за свой не выдаёт.

Подменю:

1. Обновить все модули авторов (только скачать)
2. Обновить **этот** скрипт Корги Люси с GitHub Latest (как пункт **26** → установка)
3. Проверить GitHub Latest без скачивания
0. Назад

CLI: `bash remnawave-manager.sh community-update`

---

## 25. Транспорты ноды

Добавить или снять **xHTTP, gRPC, Hysteria2** на уже установленной ноде (в том числе на другом VDS). Добавление одного транспорта не включает остальные заново. Reality остаётся.

Как пользоваться:

1. Выбор ноды: номер, UUID или **0** = все. **q** — главное меню.
2. Транспорты этой ноды:
   - **[1]** Добавить Hysteria2 (UDP/443 + sing-box UDP/8443)
   - **[2]** Добавить gRPC (VLESS Reality TCP/8443)
   - **[3]** Добавить xHTTP (VLESS Reality TCP/4443)
   - **[4]** Добавить все три (Reality остаётся)
   - **[5]** Удалить Hysteria2
   - **[6]** Удалить gRPC
   - **[7]** Удалить xHTTP
   - **[8]** Удалить все три (только Reality)
   - **[9]** Применить на **этом** сервере (нода: UFW, сертификаты в `/dev/shm`, стек Hysteria2)
   - **[0]** К **списку нод**
   - **[q]** Главное меню

На **панели** пункты 1–8 меняют профиль, inbound’ы, хосты и сквад через API (лишние хосты удаляются) и печатают **чеклист**: UUID ноды (или «все») и команду для VDS ноды — `bash remnawave-manager.sh node-transports apply`. На VDS **ноды** — **[9]** или эта команда. Схема «два сервера»: сначала панель, затем apply на ноде.

CLI:

```bash
bash remnawave-manager.sh node-transports add grpc|xhttp|hysteria2|all [uuid]
bash remnawave-manager.sh node-transports remove grpc|xhttp|hysteria2|all [uuid]
bash remnawave-manager.sh node-transports reality-only
bash remnawave-manager.sh node-transports apply
```

---

## 26. Этот скрипт

GitHub **Latest этого установщика**, не образы Docker.

1. Снова проверить Latest (без скачивания)
2. Установить Latest сейчас (`self-update`: скачать, `bash -n`, заменить этот файл и `/usr/local/bin/remnawave-manager` если есть, перезапуск)
0. Назад

С 1.3.0 главное меню само сверяется с Latest не чаще раза в 6 часов (с 1.4.3 кэш не прячет более новый тег). Не опрашивать: `--no-update-check`.

CLI: `bash remnawave-manager.sh check-update` · `check-update --apply` · `self-update` · `--version`

---

## 27. Добавить ноду

Регистрирует **ещё одну** ноду на уже работающей **панели** через API: адрес, имя, профиль, привязка, хосты, сквад. **Без** `apt full-upgrade` и **без** пункта **1**. Затем на новом VDS — пункт **3** / `install node` с Node secret из `credentials.txt`.

Только с сервера панели (не с VDS «только нода»).

CLI: `bash remnawave-manager.sh add-node`

---

## 28. Пользователи

**Только VDS панели.** Пользователи VPN через API — не пароль администратора панели.

1. Список (имя, статус, UUID)
2. Создать — имя (3–32 `A–Za-z0-9._-`, начинается с буквы), затем:
   - **срок** подписки: дни `1–36500` или `ГГГГ-ММ-ДД` (по умолчанию **365** дней)
   - лимит **трафика**: `0` = безлимит, целое = ГиБ, или `512M` / `10G` / `1T`
   - лимит **устройств** (HWID): `0` = без ограничения, иначе `1–1000`
   Тот же сквад **CorgiLusi**. Поля API: `expireAt`, `trafficLimitBytes`, `trafficLimitStrategy=NO_RESET`, опционально `hwidDeviceLimit`.
3. Включить
4. Выключить
5. Показать **ссылку подписки** (из API `subscriptionUrl` или `https://ДОМЕН_ПОДПИСКИ/shortUuid`)
0. Назад · **q** главное меню

CLI:

```bash
bash remnawave-manager.sh users list
bash remnawave-manager.sh users create Alice 365 0 0
bash remnawave-manager.sh users create Alice 30 10G 3
bash remnawave-manager.sh users create Alice 2027-12-31 512M 2
bash remnawave-manager.sh users enable UUID_ИЛИ_ИМЯ
bash remnawave-manager.sh users disable UUID_ИЛИ_ИМЯ
bash remnawave-manager.sh users sub UUID_ИЛИ_ИМЯ
```

Значения без меню: `USER_EXPIRE_DAYS`, `USER_TRAFFIC_GB`, `USER_DEVICE_LIMIT`.

---

## 29. Управление нодами

**Только VDS панели.** Действие на **одну** ноду (выбор как в пункте 25). Restart может быть `0` / `all`.

1. Список (имя, адрес, Connected/disabled, UUID)
2. Перезапустить (`forceRestart`, если API так просит)
3. Выключить
4. Включить
5. Сменить адрес (IPv4 или hostname) — `PATCH /nodes/` с `uuid` в JSON
0. Назад

CLI:

```bash
bash remnawave-manager.sh nodes list
bash remnawave-manager.sh nodes restart [UUID|all]
bash remnawave-manager.sh nodes disable UUID
bash remnawave-manager.sh nodes enable UUID
bash remnawave-manager.sh nodes address UUID 203.0.113.20
```

---

## 30. Оповещения и удалённый backup

Telegram и копия с VDS в одном меню. **Токен бота в лог установщика не пишется.**

1. Включить Telegram (токен + chat id, необязательно thread) — пишет `TELEGRAM_*` в `manager.env`, ставит `/usr/local/sbin/remnawave-health-notify.sh`, цепляет 5-минутный healthcheck
2. Отправить тест
3. Выключить оповещения (`TELEGRAM_ALERTS=0`; токен на диске остаётся)
4. Указать rclone remote и включить таймер **02:00** (`age`, затем `rclone copy`)
5. Сделать шифрованную удалённую копию **сейчас**
6. Выключить таймер удалённого backup
0. Назад

Healthcheck (не чаще раза в час на событие): API панели мёртв, Let’s Encrypt **< 21 дня**, нода не Connected.

CLI: `telegram enable|disable|test` · `backup-remote [rclone:path]` (без пути — выполнить сейчас)

---

## 31. Сертификаты

1. Срок panel / sub / Reality
2. `certbot renew` сейчас, затем reload nginx
3. Принудительно обновить эти три имени (`--force-renewal`)
4. Скопировать сертификаты в `/dev/shm` на **этом** сервере (Hysteria2)
0. Назад

В **шапке меню** — ближайший срок (жёлтым, если меньше 21 дня).

CLI: `certs` · `certs renew` · `certs force`

---

## 32. Файрвол

1. `ufw status verbose`
2. Задать **ADMIN_IP** (IPv4) и пересобрать — SSH только с этого адреса
3. Снять ADMIN_IP и пересобрать — SSH с любого IPv4 на порту SSH
4. Пересобрать UFW с текущими флагами (80/443, транспорты, нода 2222)
0. Назад

CLI: `firewall` · `firewall 203.0.113.10`

---

## 33. Заглушка подписки

**Панель / один VDS.** На **https://ДОМЕН_SUB/** отдаётся сайт питомника Corgi Lusi (фото, о питомнике, порода, галерея, контакты). Заход на домен выглядит как обычный сайт. Ссылка пользователя `https://ДОМЕН_SUB/<shortUuid>` по-прежнему идёт в `remnawave-subscription-page` на `:3010`.

По умолчанию включено при установке и `repair`. Меню:

1. Состояние
2. Включить
3. Выключить (корень SUB снова на subscription-page)
4. Обновить HTML/CSS и заново скачать фото
0. Назад

Фото из `assets/sub-stub-photos.tgz` рядом со скриптом или с GitHub Latest / jsDelivr. Если архива нет — SVG-иллюстрации. Включение и обновление идут через `sub_stub_apply`: на VDS только с нодой скрипт пишет, что домена SUB нет, и не переписывает nginx панели.

CLI:

```bash
bash remnawave-manager.sh sub-stub status
bash remnawave-manager.sh sub-stub on
bash remnawave-manager.sh sub-stub off
bash remnawave-manager.sh sub-stub refresh
```

Установка без заглушки: `--no-sub-stub`.

---

## 34. Личный кабинет

**Панель / один VDS.** Личный кабинет Material Design + Web 3.0 на **https://DOMAIN_PANEL/lk/**. Регистрация и вход: email+пароль, Telegram, VK, Яндекс. Тарифы, пробный период, покупка (**без SDK платёжных шлюзов** — mock или отметка админом), ссылка подписки Remnawave, инструкции Android / iOS / ТВ / ПК.

Админ: **https://DOMAIN_PANEL/lk/admin** (пароль панели, если не задан `CABINET_ADMIN_PASSWORD`). Там правятся вкладки меню, страницы, тарифы, инструкции и OAuth. Секреты API настроек не отдаёт.

Локальный тест без Remnawave, Docker и шлюзов:

```bash
bash remnawave-cabinet-test.sh
# http://127.0.0.1:43291/        кабинет
# http://127.0.0.1:43291/admin   админ (пароль corgi-test)
```

```bash
bash remnawave-manager.sh cabinet status
bash remnawave-manager.sh cabinet on
bash remnawave-manager.sh cabinet off
```

Установка без кабинета: `--no-cabinet`.

---

## 0. Выход

Выход из меню (`0`, `q` или `Q`). Ничего не удаляет.

---

## Лицензия

Установщик распространяется под **MIT** — [LICENSE](../LICENSE). Файлы, которые пункт **24** кладёт в `/opt/remnawave-addons`, остаются на условиях их авторов. См. [CREDITS.md](../CREDITS.md).
