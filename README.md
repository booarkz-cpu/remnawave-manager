# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.6-prod`

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.6-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## 25.1.6-prod

Hotfix bootstrap/API для актуального Remnawave Panel 3.x:

- добавлен `X-Remnawave-Client-Type: browser` во внутренние API-запросы Manager;
- это позволяет admin JWT выполнять API-вызовы, включая создание API token, согласно текущему `JwtDefaultGuard` backend;
- команда `backup` теперь сообщает понятную ошибку, если backup helper ещё не установлен;
- отключены ANSI escape-последовательности в консоли и `/var/log/remnawave-manager.log`.

## Runtime

`25.1.6+` использует proxy-aware внутренние API-запросы:

```text
X-Forwarded-For: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Host: <Panel domain>
Host: <Panel domain>
X-Remnawave-Client-Type: browser
```

## Production status

**Static audit:** green.

**Реальный VDS runtime test:** в процессе; production-ready статус не считается завершённым до успешного runtime-теста.

## SHA256

```text
e890d9cbbc92b7dad020a3bfb25662979f1fa1f453f62563db28bda1b92b2780  remnawave-manager-v25.1.6-prod.sh
```

Подробности: [CHANGELOG.md](CHANGELOG.md).
