# Changelog

## 25.1.14-prod

`repair` больше не может сломать nginx: `/etc/nginx/conf.d/ssl-params.conf` сразу восстанавливается как пустой stub, если 25.1.12 его удалил. Скачивайте релиз с GitHub Releases, не с закэшированного `raw.githubusercontent.com`.

SHA256:
будет после упаковки.

## 25.1.13-prod

Hotfix `repair` после 25.1.12: файл `/etc/nginx/conf.d/ssl-params.conf` удалялся до перезаписи `reality-site.conf`, `nginx -t` падал, панель оставалась на 502.

- старые `include .../ssl-params.conf` переписываются на snippet **до** удаления файла;
- `repair` применяет nginx только после записи всех vhost.

SHA256:
`c868a4970404dc9ae37d687f49e780a6de9ee8698115604cde1999c816b7148b`

## 25.1.12-prod

Исправление HTTP 502 на панели и странице подписки, маскировка Reality SNI под сайт о корги.

- nginx больше не использует Ubuntu `proxy_params`: в upstream уходят официальные заголовки Remnawave (`Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host`) и `proxy_http_version 1.1`, иначе ProxyCheckMiddleware панели и subscription-page рвёт сокет → nginx 502;
- TLS-параметры вынесены в `/etc/nginx/snippets/`, чтобы Ubuntu не подключала их дважды из `conf.d/` (duplicate TLSv1.2/1.3 и раздутый `proxy_headers_hash`);
- шаблон SelfSteal по умолчанию — сайт питомника **Corgi Lusi** (`corgi|simple|business|nothing`);
- команда `repair` переписывает nginx и маскировочный сайт на уже установленном VDS без Docker/БД;
- `ssh_ports | head` больше не роняет install через SIGPIPE/`set -o pipefail`.

На уже установленном `25.1.11-prod`: `sudo bash remnawave-manager.sh repair`.

SHA256:
`45e5029aa29f21b587a2726bdf191305ab4fd855e85548b73e010e8982bec3bb`

## 25.1.11-prod

Исправления установщика поверх `25.1.10-prod` (автообновление ОС сохранено).

- Node на одном VDS регистрируется через gateway Docker-сети `remnawave-network`, а не `127.0.0.1` (панель в контейнере не достучится до host-network remnanode по loopback);
- UFW в режиме `single` открывает порт Node 2222 только с Docker-подсети;
- режим `install panel` поднимает SNI-router на TCP/443;
- `ssl_reject_handshake` используется на nginx ≥ 1.19.4, иначе dummy-сертификат и `return 444`;
- Hysteria2: `sing-box run -c /etc/sing-box/config.json`;
- Prometheus scrapes host-network node-exporter как `host.docker.internal:9100`;
- в `.env` панели явно задаётся `REDIS_SOCKET=/var/run/valkey/valkey.sock`;
- `manager.env` обновляется по ключам (upsert);
- создание API token устойчиво к занятому имени (`name <= 30`);
- username администратора больше не берётся как полный email;
- пароль администратора проверяется по правилам backend (24+ / буква / цифра);
- restore `.age` определяется по расширению;
- `--admin-ip` и fail2ban учитывают все SSH-порты;
- кастомное ядро Xray монтируется в уже существующий `volumes:` node compose;
- сохранён `apt-get full-upgrade` из 25.1.10 (без авторебута).

SHA256:
`e10193fd771c386af76697b0bc42c1eddb831b21cf1d60341f6f6fe43269d239`

## 25.1.10-prod

Automatic full OS update during installation.

- runs `apt-get update` before installing dependencies;
- runs `dpkg --configure -a`;
- runs `apt-get -f install -y`;
- runs `apt-get full-upgrade -y`;
- runs `apt-get autoremove --purge -y` and `apt-get autoclean -qq`;
- does not reboot automatically; reports `/var/run/reboot-required` when present.

SHA256:
`97a9a6cdfb5d203c35e43eee87ef8977ec34e3054a9fa5ca64dfc031fedb9255`

## 25.1.9-prod

Firewall/SSH bootstrap hotfix.

- fixed SSH port detection when `sshd -T` returns no `port`;
- added fallbacks for `/etc/ssh/sshd_config` and systemd socket activation;
- UFW opens all detected SSH ports before enabling the firewall;
- preserved bootstrap ADMIN/API token fixes from 25.1.7 and 25.1.8.

SHA256:
`04edbee57c6fb0250d6d6c1e8e967553ebc37462a11460e95038068921603086`

## 25.1.8-prod

Bootstrap/API token compatibility hotfix.

- automatic API token name stays within backend `name <= 30`;
- fixed bootstrap of the minimal API token for Subscription Page.

SHA256:
`1271774b70e4f4c0b4f8574e25248b665547bc90aac2b6e59ce5d8e2824b46aa`

## 25.1.7-prod

Bootstrap persistence hotfix.

- `ADMIN_PASSWORD` is saved to `/opt/remnawave/manager.env` before API login/register;
- reruns after a partial bootstrap use the same password.

SHA256:
`6d7920b94652dce6b8ef17a9cbbbfcacaf975a3280294998ce756b73a15d6f4a`
