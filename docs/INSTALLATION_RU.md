# Установка Remnawave Manager 25.1.2-prod

## 1. Требования

Debian/Ubuntu VDS, root-доступ, публичный IPv4 и заранее настроенные DNS A-записи.

## 2. Скачать и проверить

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.2-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Ожидаемый SHA256:

```text
45b7039466597a34220ca3c32a0dcc1080e759611b6e8a43735fb9b2310781dd
```

Перед установкой:

```bash
sudo bash remnawave-manager.sh --dry-run
```

## 3. Single-VDS

```bash
sudo bash remnawave-manager.sh install single
```

Неинтерактивный пример:

```bash
sudo bash remnawave-manager.sh install single --yes   DOMAIN_PANEL=panel.example.com   DOMAIN_SUB=sub.example.com   DOMAIN_REALITY=reality.example.com   ADMIN_EMAIL=admin@example.com
```

## 4. Multi-VDS

Panel:

```bash
sudo bash remnawave-manager.sh install panel --yes   DOMAIN_PANEL=panel.example.com   DOMAIN_SUB=sub.example.com   DOMAIN_REALITY=reality.example.com   EDGE_ADDRESS=203.0.113.20   ADMIN_EMAIL=admin@example.com
```

Edge:

```bash
sudo bash remnawave-manager.sh install edge --yes   PANEL_IP=203.0.113.10   DOMAIN_REALITY=reality.example.com   ADMIN_EMAIL=admin@example.com   NODE_SECRET_KEY='секрет-ноды'
```

## 5. Проверки

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo nginx -t
sudo ss -lntup
sudo ufw status
```

## 6. Backup / Restore

```bash
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

В `25.1.2-prod` SQL dump хранится внутри backup-архива во временном виде и при restore извлекается непосредственно из архива. Это также устраняет зависимость от имени `.age`-файла.

## 7. Обновление

```bash
sudo bash remnawave-manager.sh update
```

Перед update создаётся backup. После update выполняется health/API check.

## 8. Внешние add-ons

Используйте осторожно: upstream scripts выполняют внешний код с правами root.

## 9. Удаление

```bash
sudo bash remnawave-manager.sh uninstall
```

Backup-архивы сохраняются.

## 10. Production status

Статические проверки пройдены. Реальное развертывание на VDS ещё требуется.

Следующий обязательный этап: чистый VDS -> Single-VDS -> backup -> restore -> Multi-VDS Panel/Edge.

