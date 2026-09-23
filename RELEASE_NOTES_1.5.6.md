# v1.5.6

## English

**Fix:** `https://SUB/` no longer returns **500 Internal Server Error** on nginx 1.24. The 1.5.5 vhost used `alias` on `location = /`; nginx then opened `index.htmlindex.html`. Kennel pages use `root` + `try_files`. Subscription URLs `/shortUuid` still go to Remnawave.

After updating the script, open the menu (or run `repair` / `sub-stub refresh`) so the vhost is rewritten.

```bash
bash remnawave-manager.sh self-update
# or:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.6/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.6

bash remnawave-manager.sh sub-stub refresh
# https://SUB/  → kennel (HTTP 200)
# https://SUB/<shortUuid> → Remnawave subscription
```

SHA256: `e27712e9308fbcd8fca62dae9c2549c1cd994068bac6662f8e9a173387e80c23`

Guides: [README.md](README.md) · [docs/GUIDE.en.md](docs/GUIDE.en.md) · [docs/MENU.en.md](docs/MENU.en.md) · [SECURITY.md](SECURITY.md) · [CHANGELOG.md](CHANGELOG.md).

## Русский

**Исправление:** `https://SUB/` больше не отвечает **500 Internal Server Error** на nginx 1.24. В 1.5.5 vhost использовал `alias` на `location = /`; nginx открывал `index.htmlindex.html`. Страницы питомника — `root` + `try_files`. Ссылки `/shortUuid` по-прежнему идут в Remnawave.

После обновления скрипта откройте меню (или `repair` / `sub-stub refresh`), чтобы vhost переписался.

```bash
bash remnawave-manager.sh self-update
# или:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.6/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.6

bash remnawave-manager.sh sub-stub refresh
# https://SUB/  → питомник (HTTP 200)
# https://SUB/<shortUuid> → подписка Remnawave
```

SHA256: `e27712e9308fbcd8fca62dae9c2549c1cd994068bac6662f8e9a173387e80c23`

Инструкции: [README.ru.md](README.ru.md) · [docs/GUIDE.ru.md](docs/GUIDE.ru.md) · [docs/MENU.ru.md](docs/MENU.ru.md) · [SECURITY.ru.md](SECURITY.ru.md) · [CHANGELOG.ru.md](CHANGELOG.ru.md).
