# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.4-prod`

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.4-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
```

Single-VDS:

```bash
sudo bash remnawave-manager.sh install single
```

## 25.1.4 — release hygiene

Этот релиз не меняет архитектуру `25.1.3`. Исправлены только release/CI проблемы:

- убран UTF-8 BOM из `tests/static-audit.sh`;
- исправлены исторические checksum в `SHA256SUMS`;
- checksum каждого опубликованного Manager соответствует фактическому файлу;
- GitHub Actions static audit запускается через `bash`, чтобы тестовый файл не зависел от executable bit/BOM.

## Runtime bootstrap

`25.1.3-prod` уже содержит proxy-aware внутренние API-запросы с:

```text
X-Forwarded-For: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Host: <Panel domain>
Host: <Panel domain>
```

Это исправление сохраняется в `25.1.4-prod`.

## DNS

Single-VDS:

- `panel.example.com` -> VDS IP
- `sub.example.com` -> VDS IP
- `reality.example.com` -> VDS IP

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

Статические проверки обязательны. Реальный VDS runtime test ещё продолжается на тестовом сервере.

## SHA256

```text
ac3843b37ff02c40101768a0dbb2f4c2312fc8cd9690ba78d0936b03060086f4  remnawave-manager-v25.1.4-prod.sh
```

Подробности: [CHANGELOG.md](CHANGELOG.md) и [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).

