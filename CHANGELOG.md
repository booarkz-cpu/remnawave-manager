# Changelog

## 25.1.0-prod

Production revision.

### Изменения

- удалены лишние публичные firewall-правила для локальных monitoring-портов;
- улучшено повторное использование существующего Reality Host по адресу, SNI и profile/inbound;
- сохранены Single-VDS и Multi-VDS Panel/Edge;
- сохранены TLS, UFW/fail2ban, backup/restore, update, monitoring и optional Hysteria2;
- добавлены upstream add-ons, Xray core management и внешний Xray Checker;
- русифицированы пользовательские сообщения Manager и camouflage page.

### Проверки

- `bash -n` — пройдено;
- `--help` — пройдено;
- dry-run для `single`, `panel`, `edge` — пройден;
- реальный VDS/Docker/ACME runtime deployment для этой публикации не выполнялся;
- ShellCheck не выполнялся, так как в среде публикации он отсутствовал.

## 25.0.0

Предыдущая production revision.
