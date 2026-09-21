# Авторство

**Remnawave Manager** — основная линия установщика: [booarkz-cpu/remnawave-manager](https://github.com/booarkz-cpu/remnawave-manager).

В `1.0.0` первый стабильный релиз без суффикса `-prod`.

В `25.2.7-prod` Reality-хосты получают отпечаток firefox, не chrome.

В `25.2.6-prod` скрипт запускается без `sudo` в команде: права root поднимаются сами.

В `25.2.5-prod` сквад и профили — CorgiLusi; Default-Profile удаляется после установки; у каждой ноды свой профиль.

В `25.2.4-prod` `repair` восстанавливает домены с диска, даже если в `manager.env` остался только язык.

В `25.2.3-prod` меню показывает живой статус; сертификаты Hysteria2 идут через systemd, а не crontab; страница подписки подключается к панели через HTTPS хоста.

В `25.2.2-prod` интерактивное меню описывает все функции; язык интерфейса — русский или English.

В `25.2.1-prod` привязка профиля, inbound’ов, нод, хостов и сквада выполняется через API панели. Конвертер больше не нужен как шаг установки; ссылка оставлена в меню как дополнительный инструмент.

В `25.2.0-prod` в этот скрипт добавлены функции и идеи из следующих проектов. Авторство исходных скриптов сохранено; мы не выдаём чужой код за свой.

## Rezzosoft KVN

- Репозиторий: [Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2](https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2)
- Автор: Rezzosoft KVN
- Что взято: подготовка ноды под Hysteria2 / VLESS gRPC Reality / VLESS xHTTP Reality, сертификаты в `/dev/shm`, cron, порты UFW
- **Конвертер конфигов:** https://rezzosoft.ru/converter.html  
  Пункт есть в интерактивном меню менеджера. Для установки и привязки inbound’ов конвертер не требуется.

## eGamesAPI

- Репозиторий: [eGamesAPI/remnawave-reverse-proxy](https://github.com/eGamesAPI/remnawave-reverse-proxy)
- Что взято: режимы «только панель» / «только нода», Cloudflare DNS-сертификаты, скрытый URL входа в панель, модуль `addon egames`

## DigneZzZ

- Репозиторий: [DigneZzZ/remnawave-scripts](https://github.com/DigneZzZ/remnawave-scripts)
- Что взято: CLI-команды `up`/`down`/`restart`/`logs`/`update`/`backup`, ядро Xray, модули SelfSteal, WARP/Tor (`wtm`), NetBird
