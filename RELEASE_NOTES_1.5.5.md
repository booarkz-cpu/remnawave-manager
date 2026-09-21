# v1.5.5

## English

A **Corgi Lusi kennel stub** (photos and pages) is served when someone opens the subscription domain itself. User subscription URLs keep working. Photo archive is shipped as a release asset and in the repo (`assets/sub-stub-photos.tgz`). `sub-stub refresh` does not rewrite panel nginx on a node-only VPS.

```bash
bash remnawave-manager.sh self-update
bash remnawave-manager.sh --version
# remnawave-manager 1.5.5

bash remnawave-manager.sh sub-stub on
# https://SUB/  → kennel
# https://SUB/<shortUuid> → Remnawave subscription
```

SHA256: `42a912d3f3bdf8a7a0cbc7a30db2a989bd7cdb77094bc72b3267aaf81b9a1635`

## Русский

На корне домена подписки — **заглушка питомника Corgi Lusi** (фото и страницы). Ссылки пользователей не ломаются. Архив фото — в релизе и в репозитории (`assets/sub-stub-photos.tgz`). `sub-stub refresh` на VDS только с нодой не переписывает nginx панели.

```bash
bash remnawave-manager.sh self-update
bash remnawave-manager.sh --version
# remnawave-manager 1.5.5

bash remnawave-manager.sh sub-stub on
# https://SUB/  → питомник
# https://SUB/<shortUuid> → подписка Remnawave
```

SHA256: `42a912d3f3bdf8a7a0cbc7a30db2a989bd7cdb77094bc72b3267aaf81b9a1635`
