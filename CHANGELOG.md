# Changelog

## 25.1.7-prod

Bootstrap persistence hotfix.

- `ADMIN_PASSWORD` теперь сохраняется в `/opt/remnawave/manager.env` до API login/register;
- повторный запуск после частичного сбоя bootstrap использует тот же пароль;
- добавлено более понятное сообщение при ошибке login.

SHA256:
`6d7920b94652dce6b8ef17a9cbbbfcacaf975a3280294998ce756b73a15d6f4a`

## 25.1.6-prod

Bootstrap/API hotfix.

- добавлен `X-Remnawave-Client-Type: browser` для внутренних API-запросов с admin JWT;
- исправлен bootstrap API token на актуальном Remnawave backend;
- `backup` теперь выдаёт явную ошибку при отсутствии helper;
- отключены ANSI escape-последовательности в консоли и `/var/log/remnawave-manager.log`.

SHA256:
`e890d9cbbc92b7dad020a3bfb25662979f1fa1f453f62563db28bda1b92b2780`

## 25.1.5-prod

Release/CI hygiene.

- static audit запускает Manager через `sudo`;
- checksum проверяется только для текущего релизного файла;
- убран BOM из `tests/static-audit.sh`;
- runtime-код 25.1.4 сохранён без изменений.

## 25.1.4-prod

Исправлена release-инфраструктура и исторические checksum.

## 25.1.3-prod

Исправлен ProxyCheckMiddleware bootstrap.

## 25.1.2-prod

Исправлен backup/restore PostgreSQL.

## 25.1.1-prod

Исправлены `FRONT_END_DOMAIN`, `TRUST_PROXY` и другие статические проблемы.
