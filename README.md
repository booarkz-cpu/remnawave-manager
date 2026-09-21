# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.3-prod`

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.3-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## Что автоматизирует

Single-VDS и Multi-VDS (Panel + Edge), Docker Compose, Nginx SNI routing, VLESS/Reality, Let's Encrypt/ECDSA, UFW/fail2ban, backup/restore, update, monitoring, optional Hysteria2, upstream add-ons, Xray core management и внешний Xray Checker.

## Важное исправление 25.1.3

Remnawave Panel требует reverse proxy и HTTPS. Для внутренних API-запросов Manager теперь передаёт `X-Forwarded-For: 127.0.0.1` и `X-Forwarded-Proto: https`, как показано в официальном TypeScript SDK для доступа из bridge/internal networks. citeturn764358search6

В предыдущей версии bootstrap делал локальный HTTP-запрос без этих заголовков, из-за чего backend возвращал `Reverse proxy and HTTPS are required`.

## DNS

Для Single-VDS:

- `panel.example.com` -> VDS IP
- `sub.example.com` -> VDS IP
- `reality.example.com` -> VDS IP

Backend-порты и локальные monitoring-порты не должны быть публично открыты.

## Обслуживание

```bash
sudo bash remnawave-manager.sh status
sudo bash remnawave-manager.sh doctor
sudo bash remnawave-manager.sh backup
sudo bash remnawave-manager.sh update
sudo bash remnawave-manager.sh restore /var/backups/remnawave/ARCHIVE.tgz
```

## Безопасность

Не публикуйте GitHub PAT, Remnawave API token, Node `SECRET_KEY`, пароли, age private key или Hysteria2 credentials.

После сохранения секретов удалите:

```bash
sudo rm -f /opt/remnawave/credentials.txt
```

## Production status

Статические проверки: `bash -n`, `--help`, dry-run Single/Panel/Edge.

Реальный VDS сейчас используется как первый runtime test. До успешного прохождения полного bootstrap, TLS, Node/Reality, backup и restore релиз следует считать test-production, а не окончательно validated production.

## Контрольная сумма

```text
74274f01bd10e072ab18c474490af64de36f24777cd860fce1a457eb113d9020  remnawave-manager-v25.1.3-prod.sh
```

Подробности: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md) и [CHANGELOG.md](CHANGELOG.md).

