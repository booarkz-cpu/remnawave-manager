# v1.0.0

Первый стабильный релиз Remnawave Manager без суффикса `-prod`.

- Reality-хосты (VLESS TCP, gRPC, xHTTP) с отпечатком **firefox**
- сквад и профили **CorgiLusi**, Default-Profile удаляется после установки
- запуск без `sudo` в команде

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.0.0/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
# нужно: 79cec67577feb666bc89a35452909457dba169540cecf909d8b2932f552fbe07
bash remnawave-manager.sh --lang ru
```

Уже стоит: пункт меню **4** или `bash remnawave-manager.sh protocols`.

SHA256: `79cec67577feb666bc89a35452909457dba169540cecf909d8b2932f552fbe07`
