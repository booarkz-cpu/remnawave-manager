# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.5-prod`

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.5-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## 25.1.5

Runtime-логика `25.1.4-prod` не менялась. Исправлена только release/CI-проверка:

- static audit запускает dry-run Manager через `sudo`;
- тест проверяет checksum только текущего релизного файла;
- workflow не падает из-за исторических checksum старых артефактов;
- тестовый `static-audit.sh` записан без UTF-8 BOM.

## Runtime

`25.1.3+` содержит proxy-aware внутренние API-запросы:

```text
X-Forwarded-For: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Host: <Panel domain>
Host: <Panel domain>
```

Это нужно для актуального ProxyCheckMiddleware Remnawave.

## Production status

Static audit должен быть green. Реальный VDS runtime test всё ещё обязателен.

## SHA256

```text
55a8aa4af70652d69e8572541b73b1846c0cd7e9e8aff6760e11350b7553ae8a  remnawave-manager-v25.1.5-prod.sh
```

Подробности: [CHANGELOG.md](CHANGELOG.md).

