# Журнал установки по версиям

Актуальная инструкция (как ставить, как **правильно обновить скрипт** до Latest, меню, два VDS):

- [Русский — docs/GUIDE.ru.md](GUIDE.ru.md)
- [English — docs/GUIDE.en.md](GUIDE.en.md)

Ниже — заметки по конкретным релизам (хеши, что менять после скачивания старой версии). Для повседневной работы используйте Latest и раздел 10 в GUIDE.

# Установка Remnawave Manager 1.6.3

Кабинет заново читает меню после правок в админке. Форма slug без ложного placeholder. Сначала `self-update`.

jsDelivr: `@v1.6.3` / `695fb25f93e80be3583a1dc002ea01a1a952a30dadf9ec87aecea690b90634e5`.

# Установка Remnawave Manager 1.6.2

Админ-кабинет Material You + Web 3.0. Аудит `/admin/`, X-Frame-Options, WAL. Сначала `self-update`.

jsDelivr: `@v1.6.2` / `64afdec784ba3ff468dcc46e0a982914d4697e2c7cdae05cf671ede775306543`.

# Установка Remnawave Manager 1.6.1

Аудит личного кабинета (пункт **34**): Telegram widget, правка вкладок в админке, `/lk` → `/lk/`. Тест без шлюзов: `remnawave-cabinet-test.sh`. Сначала `self-update`.

jsDelivr: `@v1.6.1` / `0a555fda5111c3bf1ecafdb3f7d9d35a1b8e7ed48516fcc5068660aab18c77fb`.

# Установка Remnawave Manager 1.6.0

Личный кабинет (пункт **34** / `cabinet`) и `remnawave-cabinet-test.sh` без платёжных шлюзов. Сначала `self-update`.

jsDelivr: `@v1.6.0` / `e194c5cfed6efc84361fd00dc4d62492cb06395a452af236e73316cd12791416`.

# Установка Remnawave Manager 1.5.5

Заглушка питомника корги на корне домена подписки (пункт **33** / `sub-stub`). Ссылки `/shortUuid` не ломаются. Сначала `self-update`.

jsDelivr: `@v1.5.5` / `42a912d3f3bdf8a7a0cbc7a30db2a989bd7cdb77094bc72b3267aaf81b9a1635`.

# Установка Remnawave Manager 1.5.4

Создание пользователя: срок подписки, лимит трафика, лимит устройств. Язык спрашивается до меню. Changelog и Security на английском и русском. Сначала `self-update`.

jsDelivr: `@v1.5.4` / `4a6200b2118c8df6f3a6f38f5efd48a0b2afa9c7358538fb7b5338391b9f7afa`.

# Установка Remnawave Manager 1.5.3

Меню не завершается на `die` пункта. `self-update` без подпроцесса. Ввод `08` безопасен. Сначала `self-update`.

jsDelivr: `@v1.5.3` / `ebfe8913476c0f04a5e13694f30b0bfbb7fa4cd0b81d5d1b9e7018906e9add98`.

# Установка Remnawave Manager 1.5.2

Аудит: пункт **13** restore, `ask`/EOF, `VERSION` из os-release, меню 27–32 не abort. Сначала `self-update`.

jsDelivr: `@v1.5.2` / `65a1a8ef96d427863c0fdad5fc765dee634f18562b34723a5e6a768acb9bc0ba`.

# Установка Remnawave Manager 1.5.1

Пункт **26**: проверка Latest больше не роняет меню. Тег с первого редиректа GitHub, запас jsDelivr. С 1.5.0: `self-update` или curl jsDelivr `@v1.5.1`.

jsDelivr: `@v1.5.1` / `445b3fac779236d95e82ea535e7cf365a8e0356249d461f4c2d1c1c0b1d7e918`.

# Установка Remnawave Manager 1.5.0

Пункты **28–32**: пользователи, ноды, Telegram/rclone, сертификаты, UFW. Пункт **23** — SHOW. Чеклист после **25** на панели. Сначала `self-update`.

jsDelivr: `@v1.5.0` / `72c9cb8ca9ac35bb03b596bb32d68ff507c43f36992d1ee615962da3f44bacdb`.

# Установка Remnawave Manager 1.4.4

Пункт **25**: `[0]` возвращает к списку нод, `q` — в главное меню. UUID не залипает. Сначала `self-update`.

jsDelivr: `@v1.4.4` / `c94a44bf4c9e5930593bfe2227b14fed1e495efd72d300ba857aa10778d37a0d`.

# Установка Remnawave Manager 1.4.3

Пункт **25** всегда спрашивает ноду. Кэш GitHub не скрывает новый Latest, если вы уже на предыдущем теге. Сначала `self-update`, затем пункт 25.

jsDelivr: `@v1.4.3` / `90dfaf451da9ec826cef431162ce3f6f59658c7aa7727b563e07a101eef89922`.

# Установка Remnawave Manager 1.4.2

Пункт **25** снимает транспорты: после «удалить Hysteria2» больше не подтягивается старый HYSTERIA2=1 из `manager.env`. Обновите скрипт (`self-update`) и повторите пункт 25 → 5.

jsDelivr: `@v1.4.2` / `f0ceb92599ccbe8e9427ad3e506938ffcb6f63ef8aee989ce5a951290171205b`.

# Установка Remnawave Manager 1.4.1

Исправление перезапуска после `self-update`: в 1.4.0 из‑за `IFS` без пробела аргумент `--lang ru` склеивался в одно слово и скрипт писал «Неизвестная команда: --lang ru». Повторно: `bash remnawave-manager.sh self-update`.

jsDelivr: `@v1.4.1` / `89bc7d2c2853925cd4cd18f5bf57a7d83cc2bb3cb73a38fb18a590957e9a1d57`.

# Установка Remnawave Manager 1.4.0

Неизвестная команда больше не печатает весь `--help`. `--version` без sudo. Пункт **26** — этот скрипт; пункт **24** — модули авторов. Пункт **27** / `add-node` регистрирует ноду без `apt full-upgrade`. Перед install — предпроверка DNS, портов 80/443, диска и Docker. Пункт **25** выбирает UUID, если нод несколько. Doctor: сертификаты Let’s Encrypt, UDP/TCP, Connected.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# актуальная сумма — SHA256SUMS, файл remnawave-manager-v1.4.0.sh
bash remnawave-manager.sh --version
bash remnawave-manager.sh --lang ru
```

jsDelivr: `@v1.4.0` / `fe91e431c96d54efed1a1d7219349578733d5fd30d9ab744f1436c3602be24de`.

# Установка Remnawave Manager 1.3.0

## 1. Подготовка

Ubuntu/Debian VDS, root-доступ, публичный IPv4 и DNS A-записи на домены Panel, Subscription и Reality SNI.

## 2. Скачать

Из корня репозитория или напрямую с GitHub:

```bash
curl -fsSL -L https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Сверьте сумму с файлом `SHA256SUMS`. Актуальный файл также называется `remnawave-manager-v1.3.0.sh`. Скачивайте через jsDelivr `@v1.3.0`, не с `raw.githubusercontent.com/main`.

Без аргументов скрипт открывает меню с описанием всех функций и предлагает язык (English / русский). Профиль, ноды, хосты и сквад привязываются через API — панель и конвертер править не нужно. Префикс `sudo` в команде не нужен: скрипт сам поднимает root.

```bash
bash remnawave-manager.sh --lang ru   # русский интерфейс
bash remnawave-manager.sh --lang en   # English UI
```

Во время `install` скрипт выполняет `apt-get full-upgrade`. Автоматически VDS не перезагружается; если появится `/var/run/reboot-required`, перезагрузите сервер после завершения установки.

## 3. Dry-run

```bash
bash remnawave-manager.sh install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

## 4. Single-VDS

```bash
bash remnawave-manager.sh install single --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

Панель работает в Docker, Node — в `network_mode: host`. Адрес Node, который панель пишет в карточку, — gateway сети `remnawave-network` (не `127.0.0.1`). Карточка, inbound’ы и хосты создаются установщиком, в UI их трогать не нужно.

## 5. Панель и нода на разных серверах

Сначала панель:

```bash
bash remnawave-manager.sh install panel --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

Скопируйте SECRET_KEY из `/opt/remnawave/credentials.txt` на сервере панели. На втором VDS:

```bash
bash remnawave-manager.sh install node --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='секрет_из_credentials.txt'
```

`install node` — синоним `install edge`. По умолчанию ставятся все транспорты: Reality (SNI TCP/443), Hysteria2 UDP/443, gRPC TCP/8443, xHTTP TCP/4443. На панели вызовите `install panel` с `EDGE_ADDRESS=<IP ноды>` или затем `bash remnawave-manager.sh protocols` — inbound’ы, хосты и сквад CorgiLusi привяжутся через API. Default-Profile будет удалён.

Повторная автопривязка на уже стоящей системе: `bash remnawave-manager.sh bind` (то же, что `protocols`) или пункт 4 меню.

Добавить или снять xHTTP / gRPC / Hysteria2 на уже установленной ноде (панель и нода на разных VDS) — **отдельный пункт 25**, не пункт 4:

```bash
# панель
bash remnawave-manager.sh node-transports add grpc
bash remnawave-manager.sh node-transports add xhttp
bash remnawave-manager.sh node-transports add hysteria2
bash remnawave-manager.sh node-transports remove grpc
bash remnawave-manager.sh node-transports reality-only

# нода
bash remnawave-manager.sh node-transports apply
```

## 6. ProxyCheckMiddleware

Panel нельзя корректно использовать без reverse proxy/HTTPS. Внутренние API-запросы идут по HTTP с заголовками `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host` и `X-Remnawave-Client-Type: browser`.

## 7. Диагностика

```bash
sudo tail -100 /var/log/remnawave-manager.log
sudo docker logs --tail=100 remnawave
bash remnawave-manager.sh doctor
```

## 8. Backup / Restore

```bash
bash remnawave-manager.sh backup
bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

Для `.age` архива нужен ключ `/opt/remnawave/backup-age.key`.

## 9. HTTP 502 после 25.1.11

Панель и subscription-page требуют `X-Forwarded-For` и `X-Forwarded-Proto: https`. Без них backend рвёт сокет, nginx отвечает 502.

Если панель уже 200, а подписка 502 — контейнер `remnawave-subscription-page` не запущен или падает из‑за API token. Скачайте **25.1.16** через jsDelivr:

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.16-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: b3d8293bb4735f48b21e456860585a80e9c9a8102f33c5b8917b8bac259197b8
grep VERSION= remnawave-manager.sh | head -1
# нужно: VERSION='25.1.16-prod'
bash remnawave-manager.sh repair
```

В логе должно быть `repair: Remnawave Manager 25.1.16-prod`. Корень домена подписки должен отвечать HTTP 200.

## 10. Production test

После bootstrap проверить Panel URL, Subscription URL, сертификаты, Node (status Connected), Reality SNI (сайт о корги), UFW, timers и backup/restore. Карточка Node / Hosts / Squads в панели должна уже быть заполнена установщиком.

## 11. Обновление до 25.2.1-prod (автопривязка)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.1-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 534353340dc8987375f5bc45242f01a97327c8d8713bfc5628f1884f891e7e60
bash remnawave-manager.sh protocols
```

Команда `protocols` (синоним `bind`) обновляет профили CorgiLusi (по одному на ноду), вешает inbound’ы, создаёт хосты и сквад CorgiLusi, удаляет Default-Profile. UI панели для этого не открывайте.

## 12. Обновление до 25.2.2-prod (меню и язык)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.2-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 989c56497e2fbf8877b5e43deb3c771bfa78a402d79b9548791cd13b6299f7c9
bash remnawave-manager.sh --lang ru
```

Меню описывает все функции. Язык спрашивается при запуске меню (Enter — текущий). Позже: пункт 22 или `--lang en|ru`.

## 13. Обновление до 25.2.3-prod (меню, 502 подписки, crontab)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.3-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 728536ee926faba23dbb642383e9320c7d37a2e3c3eb275081edce2c55cef8a8
bash remnawave-manager.sh --lang ru
```

Если панель уже стоит: в пункте 1 выберите **1) Repair** (для 502 на `sb.*`) или **2) привязка протоколов**. Не запускайте полную установку повторно без нужды. PowerShell-скрипты на этот Linux VDS не относятся.

## 14. Обновление до 25.2.4-prod (repair без DOMAIN_* в manager.env)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.4-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 0bb8ed6ec6c46a8fc02947f3a1fe45c1a3dbc2de9555cc63e5989336e4c229da
bash remnawave-manager.sh --lang ru
```

Пункт **7 Repair**. Если `manager.env` содержит только язык, домены берутся из `.env` панели, `credentials.txt` и nginx. Если скрипт всё же спросит домены — укажите panel / sub / reality (например pst / sb / blog).

## 15. Обновление до 25.2.5-prod (сквад CorgiLusi, без Default-Profile)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.5-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: d428f8fac02c9904a8dec07b585fc8f0ecafd561482b1a72c8be756c101e65e2
bash remnawave-manager.sh --lang ru
```

Пункт **4** (автопривязка) или `bash remnawave-manager.sh protocols`: сквад CorgiLusi, отдельный профиль на ноду, Default-Profile удаляется.

## 16. Обновление до 25.2.6-prod (запуск без sudo)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.6-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 5116f5be95419515f63d9546ce626ad425c3a216648a99964d5244a86ee4cedd
bash remnawave-manager.sh --lang ru
```

`sudo` в команде писать не нужно. Если вы не root, скрипт сам вызовет sudo. Справка: `bash remnawave-manager.sh --help`.

## 17. Обновление до 25.2.7-prod (отпечаток firefox)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.7-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 14704ad33250669ac1d9d95d5677cc53fb007dc87932d655843a68be4a2ac875
bash remnawave-manager.sh --lang ru
```

Пункт **4** или `bash remnawave-manager.sh protocols`: Reality / gRPC / xHTTP хосты получают fingerprint **firefox**. Hysteria2 отпечаток не использует.

## 18. Обновление до 1.0.0

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.0.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 79cec67577feb666bc89a35452909457dba169540cecf909d8b2932f552fbe07
bash remnawave-manager.sh --lang ru
```

Стабильный релиз без суффикса `-prod`. Тег: `v1.0.0`.

## 19. Обновление до 1.1.0 (Корги Люси, синее меню, модули авторов)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.1.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 82f4c523ef22167c83b841c7631bc7fd82ff798a7ef2f0681f0515406ca7817f
bash remnawave-manager.sh --lang ru
```

Автор — Корги Люси. Пункт **24** или `bash remnawave-manager.sh community-update` скачивает оригиналы Rezzosoft / eGames / DigneZzZ. `self-update` обновляет этот скрипт с GitHub Latest.

## 20. Обновление до 1.2.0 (транспорты уже установленной ноды)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.2.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: f5fe62ececf0fe5261a801bde4be0b325273b1761d7ee731df138a7fa19ca3b2
bash remnawave-manager.sh --lang ru
```

Пункт **25** или `bash remnawave-manager.sh node-transports add|remove grpc|xhttp|hysteria2|all`. На панели: профиль и хосты. На ноде: `node-transports apply`.

## 21. Обновление до 1.3.0 (автопроверка скрипта)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.3.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: dd7ece932c3dd26a93dacc0c24249dfa1b15bb8f7bd475b5b846a6d6a933c152
bash remnawave-manager.sh --lang ru
```

При открытии меню скрипт сравнивает свою версию с GitHub Latest (не чаще раза в 6 часов). Если доступна новая — предлагает установить. Без меню: `bash remnawave-manager.sh check-update`. Установить сразу: `check-update --apply`. Отключить запрос: `--no-update-check`. Пункт 24, подпункт 3 — только проверка.
