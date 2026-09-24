# Remnawave Manager — Wiki на русском

## Что это

Remnawave Manager — CLI-менеджер для развёртывания и обслуживания Remnawave Panel/Node.

Проект написан на Bash и предназначен прежде всего для Debian/Ubuntu.

Автор: **Corgi Lusi / Корги Люси**

## Установка

Полная установка:

```bash
remnawave-manager install single
```

Panel отдельно:

```bash
remnawave-manager install panel
```

Node отдельно:

```bash
remnawave-manager install node
```

## Меню

### 0 — Exit
Выход из Manager.

### 1 — Full Install
Полная установка Panel + необходимых компонентов + Node/транспортов согласно выбранной конфигурации.

### 2 — Panel Only
Установка только Remnawave Panel. Используется, когда Node находится на другом сервере.

### 3 — Node Only
Установка Node без Panel.

### 4 — Auto-bind
Автоматическая настройка и привязка транспортов:

```bash
remnawave-manager protocols
remnawave-manager bind
```

### 5 — Status
Показывает состояние установленных компонентов и сервисов.

### 6 — Doctor
Диагностика конфигурации и распространённых проблем.

### 7 — Repair
Автоматическое восстановление известных проблем.

### 8 — Logs
Просмотр логов Manager и связанных сервисов.

Основной лог:

```text
/var/log/remnawave-manager.log
```

### 9 / 10 / 11 — Up / Down / Restart

```bash
remnawave-manager up
remnawave-manager down
remnawave-manager restart
```

### 12 / 13 — Backup / Restore

```bash
remnawave-manager backup
remnawave-manager restore
```

### 14 — Remnawave Update

Обновление образов Remnawave. Это не обновление Manager и не обновление Xray.

### 15 — Uninstall

Удаление установленного окружения. Перед удалением рекомендуется сделать backup.

### 16 — Xray Core

```bash
remnawave-manager core-update
```

### 17 — Add-ons
Установка и управление дополнительными компонентами проекта.

### 18 — Stealth Login
Дополнительный механизм скрытого/защищённого доступа согласно конфигурации проекта.

### 19 — Install CLI

```bash
remnawave-manager install-script
```

### 20 — Converter
Инструменты конвертации, предусмотренные Manager.

### 21 — Help / Credits
Справка и информация об авторах/проекте.

### 22 — Language
Переключение языка интерфейса.

### 23 — URLs
Показывает используемые URL и адреса компонентов.

### 24 — Community Update
Обновление community-функций проекта.

### 25 — Node Transports

Поддерживаются:

- VLESS Reality TCP `443`;
- Hysteria2 UDP `443`;
- sing-box UDP `8443`;
- VLESS gRPC Reality TCP `8443`;
- VLESS xHTTP Reality TCP `4443`.

gRPC:

```text
/grpc
```

xHTTP:

```text
/xhttp
```

### 26 — Manager Update

```bash
remnawave-manager check-update
remnawave-manager self-update
```

### 27 — Add Node
Добавление дополнительного Node.

### 28 — Users
Управление пользователями через возможности Manager.

### 29 — Nodes
Управление Node и связанные операции.

### 30 — Alerts / Remote Backup

```bash
remnawave-manager telegram
remnawave-manager backup-remote
```

### 31 — Certificates
Управление сертификатами.

### 32 — Firewall
Настройка firewall.

### 33 — Subscription Stub
Функции Subscription Stub.

## Безопасность

Не передавайте третьим лицам:

```text
/opt/remnawave/credentials.txt
```

Также нельзя публиковать API tokens, пароли БД, `SECRET_KEY`, Telegram Bot Token, приватные ключи и другие секреты.

Внутренний Panel-порт `3000` не следует без необходимости выставлять напрямую в Интернет.

## Troubleshooting

При проблеме:

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
remnawave-manager repair
```

После изменения конфигурации:

```bash
remnawave-manager restart
```
