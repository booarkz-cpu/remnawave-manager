# v1.4.1

Исправление `self-update`: после скачивания Latest 1.4.0 перезапускался с одним аргументом `--lang ru` (у скрипта `IFS` без пробела) и писал «Неизвестная команда: --lang ru». Версия при этом уже 1.4.0 (`--version` работал). 1.4.1 принимает такой argv и передаёт язык двумя словами.

```bash
bash remnawave-manager.sh self-update
bash remnawave-manager.sh --version
# remnawave-manager 1.4.1
```

SHA256: `89bc7d2c2853925cd4cd18f5bf57a7d83cc2bb3cb73a38fb18a590957e9a1d57`
