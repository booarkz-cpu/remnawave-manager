# v1.5.3

## English

Second audit after 1.5.2. A failing menu item (`die`, API, certbot) returns to the menu instead of killing the process. `self-update` still runs in the same process (`exec`). Typing `08` in the node/user picker no longer crashes bash. A failed `curl` to the panel is HTTP 000, not the ERR trap.

Full journal: [CHANGELOG.md](CHANGELOG.md) · [CHANGELOG.ru.md](CHANGELOG.ru.md).

## Русский

Повторный аудит после 1.5.2. Пункты меню с ошибкой (`die`, API, certbot) возвращают в меню, а не гасят процесс. `self-update` по-прежнему в том же процессе (`exec`). Ввод `08` в выборе ноды/пользователя больше не роняет bash. Сбой `curl` к панели — HTTP 000, не ловушка ERR.

```bash
bash remnawave-manager.sh self-update
# или:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.3/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.3
```

SHA256: `ebfe8913476c0f04a5e13694f30b0bfbb7fa4cd0b81d5d1b9e7018906e9add98`
