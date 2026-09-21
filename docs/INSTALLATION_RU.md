# Установка Remnawave Manager 25.1.3-prod

## 1. Подготовка

Ubuntu/Debian VDS, root-доступ, публичный IPv4 и DNS A-записи.

## 2. Скачать

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.3-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Ожидаемый SHA256:

```text
74274f01bd10e072ab18c474490af64de36f24777cd860fce1a457eb113d9020
```

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

## 5. ProxyCheckMiddleware

Panel нельзя корректно использовать без reverse proxy/HTTPS. Официальный SDK показывает внутренний доступ через HTTP с `X-Forwarded-For` и `X-Forwarded-Proto: https`. citeturn764358search6

`25.1.3-prod` добавляет эти заголовки в внутренние API health/bootstrap checks.

## 6. Диагностика

```bash
sudo tail -100 /var/log/remnawave-manager.log
sudo docker logs --tail=100 remnawave
sudo bash remnawave-manager.sh doctor
```

## 7. Backup / Restore

```bash
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

## 8. Production test

После bootstrap проверить Panel URL, Subscription URL, сертификаты, Node, Reality SNI, UFW, timers и backup/restore.

Реальный runtime test обязателен.

