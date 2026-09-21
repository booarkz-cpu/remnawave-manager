# v25.2.6-prod

Run **without** `sudo` in the command. The script raises root by itself. `--help` does not ask for a password.

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v25.2.6-prod/remnawave-manager.sh \
  -o remnawave-manager.sh
chmod +x remnawave-manager.sh
bash remnawave-manager.sh --lang ru
```

Already installed: menu **4** or `bash remnawave-manager.sh protocols`.

SHA256: `5116f5be95419515f63d9546ce626ad425c3a216648a99964d5244a86ee4cedd`
