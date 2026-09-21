# Меню — полный функционал каждого пункта

[English](MENU.en.md) · [Русский](MENU.ru.md) · [README](../README.ru.md) · [Инструкция](GUIDE.ru.md)

Меню без аргументов: `bash remnawave-manager.sh`. Префикс `sudo` не пишите. Номера **1–27** фиксированы; **0** / `q` — выход.

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

**Русский** или **English**. Пишется в `RW_LANG` в `/opt/remnawave/manager.env` (на ноде без панели — env edge).

CLI: `bash remnawave-manager.sh --lang ru|en`

---

## 23. Адреса

Панель, подписка, SNI Reality и ссылка пользователя CorgiLusi. **Без паролей, JWT и секрета ноды.**

CLI: `bash remnawave-manager.sh urls` · проверка снаружи: `health`

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

На **панели** пункты 1–8 меняют профиль, inbound’ы, хосты и сквад через API (лишние хосты удаляются). На VDS **ноды** — **[9]** или `node-transports apply`. Схема «два сервера»: сначала панель, затем apply на ноде.

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

## 0. Выход

Выход из меню (`0`, `q` или `Q`). Ничего не удаляет.

---

## Лицензия

Установщик распространяется под **MIT** — [LICENSE](../LICENSE). Файлы, которые пункт **24** кладёт в `/opt/remnawave-addons`, остаются на условиях их авторов. См. [CREDITS.md](../CREDITS.md).
