# v1.5.5

## English

A **Corgi Lusi kennel stub** (photos and pages) is served when someone opens the subscription domain itself. User subscription URLs keep working. Photo archive is shipped as a release asset and in the repo (`assets/sub-stub-photos.tgz`). `sub-stub refresh` does not rewrite panel nginx on a node-only VPS.

```bash
bash remnawave-manager.sh self-update
# or:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.5/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.5

bash remnawave-manager.sh sub-stub on
# https://SUB/  → kennel
# https://SUB/<shortUuid> → Remnawave subscription
```

SHA256: `42a912d3f3bdf8a7a0cbc7a30db2a989bd7cdb77094bc72b3267aaf81b9a1635`

Guides: [README.md](README.md) · [docs/GUIDE.en.md](docs/GUIDE.en.md) · [docs/MENU.en.md](docs/MENU.en.md) · [SECURITY.md](SECURITY.md) · [CHANGELOG.md](CHANGELOG.md).

## Русский

На корне домена подписки — **заглушка питомника Corgi Lusi** (фото и страницы). Ссылки пользователей не ломаются. Архив фото — в релизе и в репозитории (`assets/sub-stub-photos.tgz`). `sub-stub refresh` на VDS только с нодой не переписывает nginx панели.

```bash
bash remnawave-manager.sh self-update
# или:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.5/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.5

bash remnawave-manager.sh sub-stub on
# https://SUB/  → питомник
# https://SUB/<shortUuid> → подписка Remnawave
```

SHA256: `42a912d3f3bdf8a7a0cbc7a30db2a989bd7cdb77094bc72b3267aaf81b9a1635`

Инструкции: [README.ru.md](README.ru.md) · [docs/GUIDE.ru.md](docs/GUIDE.ru.md) · [docs/MENU.ru.md](docs/MENU.ru.md) · [SECURITY.ru.md](SECURITY.ru.md) · [CHANGELOG.ru.md](CHANGELOG.ru.md).
