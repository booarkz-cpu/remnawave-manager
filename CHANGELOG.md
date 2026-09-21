# Changelog

## 25.1.1-prod

Исправляющая production revision после статического аудита `25.1.0-prod`.

### Исправления

- `FRONT_END_DOMAIN` теперь соответствует формату upstream: домен без `https://`. citeturn464550search1turn655685search10
- `TRUST_PROXY` для Subscription Page изменён на `1`, чтобы доверять одному reverse-proxy hop вместо `true`. citeturn464550search4
- стандартный пароль PostgreSQL из upstream sample (`postgres`) больше не принимается как production secret;
- healthcheck теперь проверяет каждый service в Compose, а не только наличие любого запущенного service;
- restore теперь импортирует PostgreSQL dump из backup;
- ошибка распаковки restore больше не подавляется;
- `core-update` и `core-restore` теперь правильно принимают каталог Node вторым позиционным аргументом;
- проверка TLS считает сертификат готовым только при наличии certificate и private key;
- default camouflage page снова соответствует русской странице Manager.

### Проверки

- `bash -n`: OK
- `--help`: OK
- dry-run `single`: OK
- dry-run `panel`: OK
- dry-run `edge`: OK
- YAML parsing compose blocks: OK
- статические assertions: OK
- ShellCheck в среде не установлен и не запускался
- реальный VDS/Docker/ACME deployment не выполнялся

### Совместимость

Upstream Node продолжает использовать официальный `remnawave/node:latest`, `NODE_PORT` и `SECRET_KEY`. citeturn226976search0turn226976search1

## 25.1.0-prod

Первая опубликованная production revision.

SHA-256:
`31784d414e5c497ff0560a517cc7df04ab4a6ded7a515bf9925513f5480ab874`

