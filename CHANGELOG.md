# Changelog

## 25.1.3-prod

Исправлена критичная ошибка bootstrap на актуальном Remnawave Backend.

### Что исправлено

- внутренние API-запросы Manager теперь передают `X-Forwarded-For: 127.0.0.1`;
- добавлен `X-Forwarded-Proto: https`;
- добавлен `X-Forwarded-Host`;
- внутренний API `Host` выставляется в Panel domain;
- `wait_api`, `doctor`, `update` API check и systemd healthcheck используют тот же proxy-aware путь;
- это устраняет ошибку `Reverse proxy and HTTPS are required` при bootstrap до публикации API через внешний Nginx.

Официальный SDK Remnawave документирует использование `x-forwarded-for` и `x-forwarded-proto=https` для доступа к Panel API из внутренних bridge-сетей. citeturn764358search6

### Runtime test

На тестовом VDS Ubuntu 24.04:

- Docker установлен успешно;
- PostgreSQL/Valkey/Backend стали healthy;
- DNS `pst.corgilusi.xyz`, `sb.corgilusi.xyz`, `blog.corgilusi.xyz` указывали на `13.143.166.48`;
- bootstrap остановился именно на ProxyCheckMiddleware из-за отсутствия proxy headers.

Следующий запуск `25.1.3-prod` должен пройти этот участок; затем продолжается TLS/Node/Reality bootstrap.

### Checks

- `bash -n`: OK
- локальный статический аудит: OK
- ShellCheck: не запускался

