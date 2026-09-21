# Changelog

## 25.1.4-prod

Release hygiene после CI-проверки `25.1.3-prod`.

### Исправления

- удалён UTF-8 BOM из `tests/static-audit.sh`;
- workflow запускает audit через `bash tests/static-audit.sh`;
- исправлена неверная историческая checksum `remnawave-manager-v25.1.2-prod.sh`;
- `SHA256SUMS` теперь содержит проверенные SHA256 для всех опубликованных версий;
- `25.1.3` proxy-aware API bootstrap сохранён без изменений.

### Проверки

- GitHub Actions static audit: должен быть green после публикации;
- локальный `bash -n`: OK;
- `--help`: OK;
- dry-run Single/Panel/Edge: OK.

## 25.1.3-prod

Исправлен ProxyCheckMiddleware bootstrap: внутренние API-запросы передают reverse-proxy headers.

## 25.1.2-prod

Исправлен backup/restore PostgreSQL.

## 25.1.1-prod

Исправлены `FRONT_END_DOMAIN`, `TRUST_PROXY`, PostgreSQL secret defaults и healthcheck.

## 25.1.0-prod

Первая опубликованная production revision.

