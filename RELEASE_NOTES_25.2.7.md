# v25.2.7-prod

Reality hosts (VLESS TCP, gRPC, xHTTP) are created with uTLS fingerprint **firefox**, not chrome. Hysteria2 does not set a fingerprint.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.7-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --lang ru
```

Already installed: menu **4** or `bash remnawave-manager.sh protocols`.

SHA256: `14704ad33250669ac1d9d95d5677cc53fb007dc87932d655843a68be4a2ac875`
