# v25.2.1-prod

Полностью автоматическая привязка: профиль, inbound’ы, ноды, хосты, сквад AUTO и пользователь AUTO создаются через API. Панель и конвертер править не нужно.

По умолчанию ставятся Reality, Hysteria2, gRPC и xHTTP.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.1-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
sudo bash remnawave-manager.sh
```

На уже стоящей системе: `sudo bash remnawave-manager.sh protocols`

SHA256: `534353340dc8987375f5bc45242f01a97327c8d8713bfc5628f1884f891e7e60`
