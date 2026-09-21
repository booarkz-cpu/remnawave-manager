# Remnawave Manager

Production-ориентированный Bash-менеджер для развёртывания и обслуживания Remnawave на Debian/Ubuntu.

**Текущая версия:** `25.1.10-prod`

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/v25.1.10-prod/remnawave-manager-v25.1.10-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## 25.1.10-prod

Firewall/SSH bootstrap hotfix:

- исправлено определение SSH-порта на системах, где `sshd -T` не возвращает `port`;
- добавлены fallback на `sshd_config`, systemd socket activation и безопасный default `22`;
- UFW открывает все найденные SSH-порты перед включением firewall;
- предыдущий bootstrap/API token hotfix 25.1.8 сохранён.

## 25.1.8-prod

Bootstrap/API token compatibility hotfix:

- автоматическое имя API token укладывается в ограничение backend `name <= 30`;
- добавлена проверка длины имени перед отправкой token;
- исправлен bootstrap минимального API token для Subscription Page;
- bootstrap persistence исправления 25.1.7 сохранены.

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
04edbee57c6fb0250d6d6c1e8e967553ebc37462a11460e95038068921603086  remnawave-manager-v25.1.10-prod.sh
```

Подробности: [CHANGELOG.md](CHANGELOG.md).


РќР° СЌС‚Р°РїРµ СѓСЃС‚Р°РЅРѕРІРєРё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РІС‹РїРѕР»РЅСЏРµС‚СЃСЏ РїРѕР»РЅРѕРµ РѕР±РЅРѕРІР»РµРЅРёРµ РїР°РєРµС‚РѕРІ РћРЎ РґРѕ СЂР°Р·РІС‘СЂС‚С‹РІР°РЅРёСЏ Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№.


РќР° СЌС‚Р°РїРµ СѓСЃС‚Р°РЅРѕРІРєРё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РІС‹РїРѕР»РЅСЏРµС‚СЃСЏ РїРѕР»РЅРѕРµ РѕР±РЅРѕРІР»РµРЅРёРµ РїР°РєРµС‚РѕРІ РћРЎ РґРѕ СЂР°Р·РІС‘СЂС‚С‹РІР°РЅРёСЏ Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№.


РќР° СЌС‚Р°РїРµ СѓСЃС‚Р°РЅРѕРІРєРё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РІС‹РїРѕР»РЅСЏРµС‚СЃСЏ РїРѕР»РЅРѕРµ РѕР±РЅРѕРІР»РµРЅРёРµ РїР°РєРµС‚РѕРІ РћРЎ РґРѕ СЂР°Р·РІС‘СЂС‚С‹РІР°РЅРёСЏ Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№.


РќР° СЌС‚Р°РїРµ СѓСЃС‚Р°РЅРѕРІРєРё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РІС‹РїРѕР»РЅСЏРµС‚СЃСЏ РїРѕР»РЅРѕРµ РѕР±РЅРѕРІР»РµРЅРёРµ РїР°РєРµС‚РѕРІ РћРЎ РґРѕ СЂР°Р·РІС‘СЂС‚С‹РІР°РЅРёСЏ Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№.


           .
