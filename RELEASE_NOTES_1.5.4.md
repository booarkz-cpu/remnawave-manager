# v1.5.4

## English

User create (menu **28** / `users create`) now asks for **subscription expiry** (days or `YYYY-MM-DD`, default 365), a **traffic cap** (`0` / `10` GB / `512M` / `10G` / `1T`), and a **device limit** (`0` = no HWID cap, else 1–1000). Opening the menu asks for **language first**. Changelogs: [CHANGELOG.md](CHANGELOG.md) · [CHANGELOG.ru.md](CHANGELOG.ru.md). Security: [SECURITY.md](SECURITY.md) · [SECURITY.ru.md](SECURITY.ru.md). CLI `KEY=VALUE` can no longer overwrite `PATH` / `IFS` / `LD_PRELOAD`.

```bash
bash remnawave-manager.sh self-update
# or:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.4/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.4
```

SHA256: `4a6200b2118c8df6f3a6f38f5efd48a0b2afa9c7358538fb7b5338391b9f7afa`

## Русский

Создание пользователя (пункт **28** / `users create`) спрашивает **срок подписки** (дни или `ГГГГ-ММ-ДД`, по умолчанию 365), **лимит трафика** (`0` / `10` ГБ / `512M` / `10G` / `1T`) и **лимит устройств** (`0` = без HWID, иначе 1–1000). При запуске меню **сначала язык**. Журналы: [CHANGELOG.md](CHANGELOG.md) · [CHANGELOG.ru.md](CHANGELOG.ru.md). Безопасность: [SECURITY.md](SECURITY.md) · [SECURITY.ru.md](SECURITY.ru.md). CLI `KEY=VALUE` больше не затирает `PATH` / `IFS` / `LD_PRELOAD`.

```bash
bash remnawave-manager.sh self-update
# или:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.4/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.4
```

SHA256: `4a6200b2118c8df6f3a6f38f5efd48a0b2afa9c7358538fb7b5338391b9f7afa`
