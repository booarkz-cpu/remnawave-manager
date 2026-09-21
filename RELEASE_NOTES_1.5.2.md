# v1.5.2

Аудит обычных / важных / критических ошибок установщика. Пункт **13** снова восстанавливает архив. Меню не падает на `return 1` (нода-only, пустой список, certbot, rclone без адреса). `ask` на EOF отменяется. `/etc/os-release` больше не затирает `VERSION`. Self-update: `bash remnawave-manager.sh self-update`.

```bash
bash remnawave-manager.sh self-update
# или:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.2/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.2
```

SHA256: `65a1a8ef96d427863c0fdad5fc765dee634f18562b34723a5e6a768acb9bc0ba`
