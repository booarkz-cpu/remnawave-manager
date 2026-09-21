# Changelog

## 25.2.4-prod

`repair` больше не требует заполненный `manager.env`. Домены поднимаются из `.env` панели, `credentials.txt`, nginx и Let's Encrypt. `--lang` не создаёт пустой env, из‑за которого пункт 7 падал с «нет DOMAIN_PANEL». `manager.env` больше не `source` — пароли с `$` и `&` больше не ломают загрузку доменов.

SHA256:
`0bb8ed6ec6c46a8fc02947f3a1fe45c1a3dbc2de9555cc63e5989336e4c229da`

## 25.2.3-prod

Красивое двуязычное меню с живым статусом и исправления с живого VDS: 502 подписки, `curl: (52) Empty reply`, `"-":0: bad minute` в crontab.

- меню: рамка, цвет на TTY, две строки на пункт, шапка panel/sub/node, пункт 23 «Адреса»;
- повторный выбор «полная установка» на уже стоящей панели предлагает repair / bind, а не `apt full-upgrade`;
- страница подписки ходит в панель через `https://DOMAIN_PANEL` + `extra_hosts` (ProxyCheck больше не рвёт сокет);
- `wait_subscription` не спамит curl 52 и не валит установку;
- сертификаты Hysteria2 копируются systemd-таймером, а не `crontab -` (пустой stdin при `set -e` давал bad minute и обрывал `protocols`).

SHA256:
`728536ee926faba23dbb642383e9320c7d37a2e3c3eb275081edce2c55cef8a8`

## 25.2.2-prod

Интерактивное меню с описанием каждой функции и выбор языка интерфейса (английский / русский). На GitHub два README: [English](README.md) и [Русский](README.ru.md).

- пункт 22 меню, `--lang en|ru` и `RW_LANG` в `manager.env`;
- меню покрывает установку, bind, status/doctor/repair, up/down/restart, backup/restore, update, uninstall, ядро Xray, модули, stealth, CLI и конвертер;
- справка `--help` печатается на выбранном языке.

SHA256:
`989c56497e2fbf8877b5e43deb3c771bfa78a402d79b9548791cd13b6299f7c9`

## 25.2.1-prod

Полностью автоматическая привязка без правок в панели и без конвертера.

- UPDATE профиля/ноды/хоста идёт на коллекцию (`PATCH /config-profiles/`, `PATCH /nodes/`, `PATCH /hosts/`) с `uuid` в JSON, как в backend-contract 3.4.x;
- после обновления профиля все inbound UUID вешаются на ноды (`POST /nodes/bulk-actions/profile-modification`, запасной путь — PATCH каждой ноды);
- хосты создаются с `path`/`host` для gRPC и xHTTP, `alpn=h3` для Hysteria2 и массивом `nodes`;
- сквад AUTO получает все inbound’ы; пользователь AUTO и URL подписки появляются без UI;
- по умолчанию включаются Reality + Hysteria2 + gRPC + xHTTP (`--reality-only`, если нужен только Reality).

На уже установленном 25.2.0: скачайте `@v25.2.1-prod` и выполните `sudo bash remnawave-manager.sh protocols`.

SHA256:
`534353340dc8987375f5bc45242f01a97327c8d8713bfc5628f1884f891e7e60`

## 25.2.0-prod

Русское меню и мультипротокол. Панель и нода ставятся на разные серверы. В установщик добавлены функции Rezzosoft KVN, eGamesAPI и DigneZzZ (авторство сохранено).

- меню без аргументов; `install panel` / `install node`; Reality, Hysteria2, gRPC, xHTTP;
- конвертер https://rezzosoft.ru/converter.html в меню и справке;
- `/dev/shm` и Let's Encrypt в compose ноды, cron сертификатов Hysteria2;
- `up`/`down`/`restart`/`logs`, `stealth`, `install-script`, Cloudflare DNS при `CLOUDFLARE_API_TOKEN`.

SHA256:
`86ffcb6e7ff764125ccf2f38feb9c737e9b7ae579d86519f9ce8019adad06211`

## 25.1.16-prod

Панель после 25.1.15 отвечает 200, страница подписки оставалась на 502: `repair` не поднимал `remnawave-subscription-page`. Контейнер падает на старте, если API token не читает `/system/metadata` (`exit(1)`). `CUSTOM_SUB_PREFIX=sub` прятал UI с корня домена.

- `repair` проверяет token через `/system/metadata`, при необходимости создаёт новый, переписывает `.env` и `docker compose up --force-recreate --wait`;
- `CUSTOM_SUB_PREFIX` пустой, `SUB_PUBLIC_DOMAIN` = домен подписки без `/sub` (как в официальном bundled);
- `curl -I https://sub.example.com` должен быть HTTP 200.

SHA256:
`b3d8293bb4735f48b21e456860585a80e9c9a8102f33c5b8917b8bac259197b8`

## 25.1.15-prod

Ubuntu nginx 1.24 не знает директиву `http2 on;` (она появилась в 1.25.1). Vhost снова используют `listen ... ssl http2;`.

SHA256:
`15ad868699b467264ffda6354b94cf9fc6961b02569adcce36c480c131464835`

## 25.1.14-prod

`repair` больше не может сломать nginx: `/etc/nginx/conf.d/ssl-params.conf` сразу восстанавливается как пустой stub, если 25.1.12 его удалил. Скачивайте релиз с GitHub Releases, не с закэшированного `raw.githubusercontent.com`.

SHA256:
`e94215cc2dfb6e829ee8af449569d43b0d2f1e910017c8ebc40a1766d9f0e6a0`

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
