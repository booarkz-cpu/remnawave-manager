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

SHA256: `67052bd1206712f1a2dd6a15bbfee66539b4813031628d93f02ea98c778d987c`
