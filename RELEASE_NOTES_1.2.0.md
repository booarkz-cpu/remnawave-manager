# v1.2.0

Пункт **25** — транспорты уже установленной ноды. Можно добавить или снять xHTTP, gRPC и Hysteria2, в том числе когда нода стоит на другом сервере. Это отдельный пункт, не полная автопривязка (пункт 4).

На панели: профиль CorgiLusi, inbound’ы, хосты, сквад; лишние хосты удаляются. На ноде: `node-transports apply` открывает или закрывает порты UFW, кладёт сертификаты в `/dev/shm` и поднимает/снимает sing-box Hysteria2. Добавление одного протокола не включает остальные заново.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.2.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: f5fe62ececf0fe5261a801bde4be0b325273b1761d7ee731df138a7fa19ca3b2
bash remnawave-manager.sh --lang ru
```

- панель: `bash remnawave-manager.sh node-transports add grpc|xhttp|hysteria2|all`
- снять: `bash remnawave-manager.sh node-transports remove grpc|xhttp|hysteria2|all`
- только Reality: `bash remnawave-manager.sh node-transports reality-only`
- нода: `bash remnawave-manager.sh node-transports apply`

SHA256: `f5fe62ececf0fe5261a801bde4be0b325273b1761d7ee731df138a7fa19ca3b2`
