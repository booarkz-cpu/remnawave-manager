# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.7-prod`

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/v25.1.7-prod/remnawave-manager-v25.1.7-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## 25.1.7-prod

Bootstrap persistence hotfix:

- `ADMIN_PASSWORD` сохраняется в `/opt/remnawave/manager.env` до первого API login/register;
- повторный запуск после частично неуспешного bootstrap больше не генерирует новый пароль;
- bootstrap сообщает понятную ошибку при неверном сохранённом пароле.

## 25.1.6-prod

Bootstrap/API hotfix для актуального Remnawave Panel 3.x:

- добавлен `X-Remnawave-Client-Type: browser` во внутренние API-запросы Manager;
- команда `backup` сообщает понятную ошибку, если backup helper ещё не установлен;
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
6d7920b94652dce6b8ef17a9cbbbfcacaf975a3280294998ce756b73a15d6f4a  remnawave-manager-v25.1.7-prod.sh
```

Подробности: [CHANGELOG.md](CHANGELOG.md).
