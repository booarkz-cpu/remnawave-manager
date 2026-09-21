# v1.5.1

Пункт **26** больше не падает на «Ошибка в строке … (код 1)» после неудачной проверки Latest. Тег читается с первого редиректа GitHub, не с CDN без версии. Запас: atom и jsDelivr. `self-update` при недоступном GitHub берёт jsDelivr.

На 1.5.0 можно сразу:

```bash
bash remnawave-manager.sh self-update
# или, если GitHub с VDS не открывается:
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.1/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --version
# remnawave-manager 1.5.1
```

SHA256: `445b3fac779236d95e82ea535e7cf365a8e0356249d461f4c2d1c1c0b1d7e918`
