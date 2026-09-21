# Changelog

## 25.1.5-prod

Release/CI hygiene.

- static audit запускает Manager через `sudo`;
- checksum проверяется только для текущего релизного файла;
- убран BOM из `tests/static-audit.sh`;
- runtime-код 25.1.4 сохранён без изменений.

SHA256:
`55a8aa4af70652d69e8572541b73b1846c0cd7e9e8aff6760e11350b7553ae8a`

## 25.1.4-prod

Исправлена release-инфраструктура и исторические checksum.

## 25.1.3-prod

Исправлен ProxyCheckMiddleware bootstrap.

## 25.1.2-prod

Исправлен backup/restore PostgreSQL.

## 25.1.1-prod

Исправлены `FRONT_END_DOMAIN`, `TRUST_PROXY` и другие статические проблемы.

