# v25.1.15-prod

Ubuntu nginx 1.24: неизвестная директива `http2 on;` (появилась только в 1.25.1). Vhost снова слушают `listen ... ssl http2;`.

SHA256: `15ad868699b467264ffda6354b94cf9fc6961b02569adcce36c480c131464835`

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.15-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
grep VERSION= remnawave-manager.sh | head -1
sudo bash remnawave-manager.sh repair
```

В логе: `repair: Remnawave Manager 25.1.15-prod`.
