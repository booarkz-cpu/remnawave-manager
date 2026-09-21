# v1.5.3

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
