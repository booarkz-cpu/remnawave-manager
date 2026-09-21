# Установка Remnawave Manager 25.1.15-prod

## 1. Подготовка

Ubuntu/Debian VDS, root-доступ, публичный IPv4 и DNS A-записи на домены Panel, Subscription и Reality SNI.

## 2. Скачать

Из корня репозитория или напрямую с GitHub:

```bash
curl -fsSL -L https://github.com/booarkz-cpu/remnawave-manager/releases/latest/download/remnawave-manager.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Сверьте сумму с файлом `SHA256SUMS`. Актуальный файл также называется `remnawave-manager-v25.1.15-prod.sh`. Скачивайте через jsDelivr `@v25.1.15-prod`, не с `raw.githubusercontent.com/main`.

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

Панель работает в Docker, Node — в `network_mode: host`. Адрес Node в карточке панели — gateway сети `remnawave-network` (не `127.0.0.1`).

## 5. Multi-VDS

```bash
sudo bash remnawave-manager.sh install panel --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com

sudo bash remnawave-manager.sh install edge --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='секрет_из_credentials_панели'
```

В режиме panel HTTPS слушает 443 и маршрутизирует SNI на панель и subscription page. Reality inbound живёт на edge.

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

Скачайте **25.1.15** через jsDelivr (nginx 1.24 на Ubuntu не принимает `http2 on;`):

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.15-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 15ad868699b467264ffda6354b94cf9fc6961b02569adcce36c480c131464835
grep VERSION= remnawave-manager.sh | head -1
# нужно: VERSION='25.1.15-prod'
sudo bash remnawave-manager.sh repair
```

В логе должно быть `repair: Remnawave Manager 25.1.15-prod`.

## 10. Production test

После bootstrap проверить Panel URL, Subscription URL, сертификаты, Node (status Connected), Reality SNI (сайт о корги), UFW, timers и backup/restore.
