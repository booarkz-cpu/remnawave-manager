# v1.4.2

Пункт **25** не снимал транспорты: после «удалить Hysteria2» `sync_node_transports` снова читал `HYSTERIA2=1` из `manager.env`, пересобирал профиль со всеми inbound’ами и оставлял sing-box. Выбор add/remove теперь сохраняется до hydrate и пишется в env.

```bash
bash remnawave-manager.sh self-update
bash remnawave-manager.sh --version
# remnawave-manager 1.4.2
# пункт 25 → 5 снова: в логе должно быть «Reality + gRPC + xHTTP», без Hysteria2
```

SHA256: `f0ceb92599ccbe8e9427ad3e506938ffcb6f63ef8aee989ce5a951290171205b`
