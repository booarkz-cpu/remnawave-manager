# Установка Remnawave Manager 25.2.2-prod

## 1. Подготовка

Ubuntu/Debian VDS, root-доступ, публичный IPv4 и DNS A-записи на домены Panel, Subscription и Reality SNI.

## 2. Скачать

Из корня репозитория или напрямую с GitHub:

```bash
curl -fsSL -L https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Сверьте сумму с файлом `SHA256SUMS`. Актуальный файл также называется `remnawave-manager-v25.2.2-prod.sh`. Скачивайте через jsDelivr `@v25.2.2-prod`, не с `raw.githubusercontent.com/main`.

Без аргументов скрипт открывает меню с описанием всех функций и предлагает язык (English / русский). Профиль, ноды, хосты и сквад привязываются через API — панель и конвертер править не нужно.

```bash
sudo bash remnawave-manager.sh --lang ru   # русский интерфейс
sudo bash remnawave-manager.sh --lang en   # English UI
```

Во время `install` скрипт выполняет `apt-get full-upgrade`. Автоматически VDS не перезагружается; если появится `/var/run/reboot-required`, перезагрузите сервер после завершения установки.

## 3. Dry-run

```bash
sudo bash remnawave-manager.sh install single --dry-run --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

## 4. Single-VDS

```bash
sudo bash remnawave-manager.sh install single --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

Панель работает в Docker, Node — в `network_mode: host`. Адрес Node, который панель пишет в карточку, — gateway сети `remnawave-network` (не `127.0.0.1`). Карточка, inbound’ы и хосты создаются установщиком, в UI их трогать не нужно.

## 5. Панель и нода на разных серверах

Сначала панель:

```bash
sudo bash remnawave-manager.sh install panel --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

Скопируйте SECRET_KEY из `/opt/remnawave/credentials.txt` на сервере панели. На втором VDS:

```bash
sudo bash remnawave-manager.sh install node --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='секрет_из_credentials.txt'
```

`install node` — синоним `install edge`. По умолчанию ставятся все транспорты: Reality (SNI TCP/443), Hysteria2 UDP/443, gRPC TCP/8443, xHTTP TCP/4443. На панели вызовите `install panel` с `EDGE_ADDRESS=<IP ноды>` или затем `sudo bash remnawave-manager.sh protocols` — inbound’ы, хосты и сквад AUTO привяжутся через API.

Повторная автопривязка на уже стоящей системе: `sudo bash remnawave-manager.sh bind` (то же, что `protocols`) или пункт 4 меню.

## 6. ProxyCheckMiddleware

Panel нельзя корректно использовать без reverse proxy/HTTPS. Внутренние API-запросы идут по HTTP с заголовками `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host` и `X-Remnawave-Client-Type: browser`.

## 7. Диагностика

```bash
sudo tail -100 /var/log/remnawave-manager.log
sudo docker logs --tail=100 remnawave
sudo bash remnawave-manager.sh doctor
```

## 8. Backup / Restore

```bash
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
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
sudo bash remnawave-manager.sh repair
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
sudo bash remnawave-manager.sh protocols
```

Команда `protocols` (синоним `bind`) обновляет AUTO-PROFILE, вешает все inbound’ы на ноды, создаёт хосты и сквад AUTO. UI панели для этого не открывайте.

## 12. Обновление до 25.2.2-prod (меню и язык)

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.2-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 989c56497e2fbf8877b5e43deb3c771bfa78a402d79b9548791cd13b6299f7c9
sudo bash remnawave-manager.sh --lang ru
```

Меню описывает все функции. Язык: пункт 22 или `--lang en|ru`.
