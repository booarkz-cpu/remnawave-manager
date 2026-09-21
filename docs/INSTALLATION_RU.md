# Установка Remnawave Manager v25.1.1-prod

## 1. Подготовка

Нужен Debian/Ubuntu VDS с root-доступом и настроенными DNS A-записями.

## 2. Скачать и проверить

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.1-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Ожидаемый SHA-256:

```text
4b2bb90bdc9418e25b59bd865219c378bc170c716fa2f21137fffa9adceb6bee
```

Перед изменениями:

```bash
sudo bash remnawave-manager.sh --dry-run
```

## 3. Single-VDS

```bash
sudo bash remnawave-manager.sh install single --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

## 4. Multi-VDS

Panel:

```bash
sudo bash remnawave-manager.sh install panel --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com
```

Edge:

```bash
sudo bash remnawave-manager.sh install edge --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='секрет-ноды'
```

Официальная документация требует ограничить `NODE_PORT` только IP Panel. citeturn226976search0

## 5. Проверки

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo nginx -t
sudo ss -lntup
sudo ufw status
```

## 6. Restore

```bash
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

В `25.1.1-prod` restore восстанавливает PostgreSQL dump из того же backup-архива.

## 7. Не забыть

После сохранения credentials в защищённом месте удалите `/opt/remnawave/credentials.txt`.

Не запускайте production без отдельного теста backup/restore.

## 8. Производственный статус

`25.1.1-prod` прошёл статические проверки:

- `bash -n`;
- `--help`;
- dry-run `single`;
- dry-run `panel`;
- dry-run `edge`;
- Python assertions;
- YAML parsing compose-фрагментов.

Реальный VDS runtime test всё ещё обязателен.

