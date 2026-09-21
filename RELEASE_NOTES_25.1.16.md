# v25.1.16-prod

Панель 200, подписка 502: `repair` не поднимал `remnawave-subscription-page`. Контейнер выходит при старте, если token не читает `/system/metadata`. Корень домена больше не прячется за `CUSTOM_SUB_PREFIX=sub`.

SHA256: `b3d8293bb4735f48b21e456860585a80e9c9a8102f33c5b8917b8bac259197b8`

```bash
rm -f remnawave-manager.sh
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.1.16-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
grep VERSION= remnawave-manager.sh | head -1
sudo bash remnawave-manager.sh repair
```

В логе: `repair: Remnawave Manager 25.1.16-prod`. Затем `curl -I` домена подписки должен быть HTTP 200.
