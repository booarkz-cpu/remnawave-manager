# v25.2.3-prod

Compact bilingual menu with live panel/sub/node health. Fixes from the live VDS: subscription HTTP 502 / `curl 52`, and `protocols` aborting on `"-":0: bad minute` (empty crontab under `set -e`).

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.3-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
sudo bash remnawave-manager.sh --lang ru
```

Already installed: menu item 1 → Repair (502) or re-bind. Item 7 is `repair`. Item 23 prints URLs without passwords.

SHA256: `728536ee926faba23dbb642383e9320c7d37a2e3c3eb275081edce2c55cef8a8`
