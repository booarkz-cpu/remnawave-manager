# Установка Remnawave Manager 25.1.0-prod

## Требования

Рекомендуется чистый Debian или Ubuntu с root-доступом, публичным IPv4 и заранее настроенными DNS A-записями.

## Скачать и проверить

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.0-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
```

Ожидаемый SHA-256:

```text
31784d414e5c497ff0560a517cc7df04ab4a6ded7a515bf9925513f5480ab874
```

Перед установкой:

```bash
sudo bash remnawave-manager.sh --dry-run
```

## Single-VDS

```bash
sudo bash remnawave-manager.sh install single --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com
```

## Multi-VDS

Panel VDS:

```bash
sudo bash remnawave-manager.sh install panel --yes \
  DOMAIN_PANEL=panel.example.com \
  DOMAIN_SUB=sub.example.com \
  DOMAIN_REALITY=reality.example.com \
  EDGE_ADDRESS=203.0.113.20 \
  ADMIN_EMAIL=admin@example.com
```

Edge VDS:

```bash
sudo bash remnawave-manager.sh install edge --yes \
  PANEL_IP=203.0.113.10 \
  DOMAIN_REALITY=reality.example.com \
  ADMIN_EMAIL=admin@example.com \
  NODE_SECRET_KEY='секрет-ноды'
```

На Edge TCP/2222 должен быть доступен только с IP Panel.

## TLS и Reality

DNS должен уже указывать на правильный VDS, а TCP/80 должен быть доступен для ACME webroot.

Менеджер создаёт Config Profile с VLESS RAW + REALITY и локальным camouflage-site на `127.0.0.1:9450`.

## Проверка

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo nginx -t
sudo ss -lntup
```

## Backup и update

```bash
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh update
```

Перед update создаётся backup; после обновления выполняется health/API check.

## Дополнительные сервисы

```bash
sudo bash remnawave-manager.sh install single --monitoring
sudo bash remnawave-manager.sh install single --hysteria2
```

Hysteria2 работает отдельно через sing-box на UDP/8443 и не является inbound Config Profile Xray.

## Безопасность

Секреты сохраняются в `/opt/remnawave`. После безопасного переноса удалите `/opt/remnawave/credentials.txt`.

Не выполняйте restore архивов неизвестного происхождения и не публикуйте API tokens, Node SECRET_KEY, age keys или `.env`.

## Известные caveats

- Node bootstrap автоматизируется через API и не является точной копией UI-сценария.
- `AUTO-PROFILE` переиспользуется при rerun без полной reconciliation всех полей.
- Upstream Compose и `.env.sample` не закреплены на конкретном commit.
- Внешние add-ons исполняют собственные сторонние скрипты.
