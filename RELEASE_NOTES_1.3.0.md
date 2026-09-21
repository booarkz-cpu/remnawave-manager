# v1.3.0

Автоматическая проверка обновления скрипта. При открытии меню сравнивается текущий `VERSION` с GitHub Latest. Если есть новее — предлагается установить. Повторный запрос к GitHub не чаще чем раз в 6 часов (`LAST_UPDATE_CHECK_AT` в `manager.env`). Сеть недоступна — меню открывается как обычно.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.3.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: dd7ece932c3dd26a93dacc0c24249dfa1b15bb8f7bd475b5b846a6d6a933c152
bash remnawave-manager.sh --lang ru
```

- меню само спрашивает, если GitHub Latest новее
- `bash remnawave-manager.sh check-update`
- `bash remnawave-manager.sh check-update --apply`
- `--no-update-check` — не опрашивать GitHub
- пункт 24 → 3 — только проверка, без скачивания

SHA256: `dd7ece932c3dd26a93dacc0c24249dfa1b15bb8f7bd475b5b846a6d6a933c152`
