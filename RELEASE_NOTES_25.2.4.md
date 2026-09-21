# v25.2.4-prod

Repair recovers panel / subscription / Reality domains from the panel `.env`, `credentials.txt`, nginx and Let's Encrypt. `--lang` no longer creates an empty `manager.env` that made item 7 fail with “DOMAIN_PANEL missing”. Env files are parsed as KEY=VALUE (not `source`), so passwords with `$` or `&` no longer drop the rest of the file.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.4-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
sudo bash remnawave-manager.sh --lang ru
```

Menu **7 (repair)**. If domains are detected they are reused; otherwise the script asks.

SHA256: `0bb8ed6ec6c46a8fc02947f3a1fe45c1a3dbc2de9555cc63e5989336e4c229da`
