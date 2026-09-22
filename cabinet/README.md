# Corgi Lusi user cabinet

Python 3 stdlib. **No payment-gateway SDKs.**

## Test (no Remnawave, no OAuth apps)

From the repo root:

```bash
bash remnawave-cabinet-test.sh
```

- User: http://127.0.0.1:43291/
- Admin: http://127.0.0.1:43291/admin  (`corgi-test`)
- Telegram / VK / Yandex buttons use mock login
- Buy/trial uses mock checkout

## Production

Menu **34** / `cabinet on` on the panel VPS. URL: `https://DOMAIN_PANEL/lk/`.
