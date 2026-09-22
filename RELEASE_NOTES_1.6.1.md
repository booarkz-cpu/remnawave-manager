# v1.6.1

## English

Audit of the **1.6.0 user cabinet** (menu **34**). Telegram Login Widget no longer fails the OAuth `state` check. Custom menu titles/HTML are sanitized; the admin UI can **edit** existing tabs and tariffs. `/lk` redirects to `/lk/`. Bad order ids return 400 instead of 500. Deleting a tariff that already has orders disables it instead of crashing SQLite. Test harness still has **no payment-gateway SDKs**.

```bash
bash remnawave-manager.sh self-update
bash remnawave-cabinet-test.sh
# http://127.0.0.1:43291/
# admin password: corgi-test
```

SHA256: `0a555fda5111c3bf1ecafdb3f7d9d35a1b8e7ed48516fcc5068660aab18c77fb`

Guides: [README.md](README.md) · [docs/GUIDE.en.md](docs/GUIDE.en.md) · [docs/MENU.en.md](docs/MENU.en.md) · [SECURITY.md](SECURITY.md) · [CHANGELOG.md](CHANGELOG.md).

## Русский

Аудит личного кабинета **1.6.0** (пункт **34**). Виджет Telegram больше не падает на проверке OAuth `state`. Названия и HTML вкладок очищаются; админ **редактирует** существующие вкладки и тарифы. `/lk` редиректит на `/lk/`. Неверный id заказа — 400, не 500. Удаление тарифа с заказами отключает его, а не роняет SQLite. Тест по-прежнему **без SDK платёжных шлюзов**.

```bash
bash remnawave-manager.sh self-update
bash remnawave-cabinet-test.sh
# http://127.0.0.1:43291/
# пароль админа: corgi-test
```

SHA256: `0a555fda5111c3bf1ecafdb3f7d9d35a1b8e7ed48516fcc5068660aab18c77fb`

Инструкции: [README.ru.md](README.ru.md) · [docs/GUIDE.ru.md](docs/GUIDE.ru.md) · [docs/MENU.ru.md](docs/MENU.ru.md) · [SECURITY.ru.md](SECURITY.ru.md) · [CHANGELOG.ru.md](CHANGELOG.ru.md).
