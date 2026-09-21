# v1.4.0

Неизвестная команда больше не печатает весь `--help`. `--version` работает без sudo. Пункт **26** обновляет этот скрипт (пункт **24** остаётся для модулей авторов). Пункт **27** / `add-node` регистрирует ноду в панели через API без `apt full-upgrade`. Перед установкой — предпроверка DNS, портов 80/443, диска и Docker. Пункт **25** предлагает UUID, если нод несколько (`0` = все). Doctor показывает версию скрипта vs GitHub Latest, срок Let’s Encrypt, UDP/443 и TCP/8443/4443, Connected нод.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.4.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: fe91e431c96d54efed1a1d7219349578733d5fd30d9ab744f1436c3602be24de
bash remnawave-manager.sh --version
bash remnawave-manager.sh --lang ru
```

- `bash remnawave-manager.sh --version`
- неизвестная команда → короткий текст и `self-update`
- пункт **26** / `self-update` / `check-update`
- пункт **27** / `add-node`
- пункт **25** — выбор ноды
- `doctor` — сертификаты, порты, Connected

SHA256: `fe91e431c96d54efed1a1d7219349578733d5fd30d9ab744f1436c3602be24de`
