# Changelog

## 25.1.2-prod

Исправляющая revision после дополнительного статического аудита.

### Исправления

- backup больше не оставляет отдельный незашифрованный PostgreSQL dump в `/var/backups/remnawave`;
- SQL dump включается непосредственно в backup-архив из временного каталога;
- restore ищет SQL dump внутри архива и не зависит от имени исходного `.tgz` или `.age`;
- `.age` restore теперь проходит тот же DB recovery path;
- ошибки `docker compose up` при restore больше не проглатываются;
- ошибка `nginx -t` после restore больше не игнорируется;
- версия Manager обновлена до `25.1.2-prod`.

### Проверки

- `bash -n`: OK
- `--help`: OK
- dry-run `single`: OK
- dry-run `panel`: OK
- dry-run `edge`: OK
- статические assertions: OK
- ShellCheck: не запускался
- реальный VDS/Docker/ACME runtime deployment: не выполнялся

## 25.1.1-prod

Исправления `FRONT_END_DOMAIN`, `TRUST_PROXY`, PostgreSQL secret defaults, healthcheck и аргументов Xray core.

## 25.1.0-prod

Первая опубликованная production revision.

