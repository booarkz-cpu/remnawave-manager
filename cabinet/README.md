# Corgi Lusi user cabinet

Python 3 stdlib. **No payment-gateway SDKs.** Version **1.6.3**.

## Test (no Remnawave, no OAuth apps)

From the repo root:

```bash
bash remnawave-cabinet-test.sh
```

- User: http://127.0.0.1:43291/
- Admin: http://127.0.0.1:43291/admin  (`corgi-test`) — Material You + Web 3.0 rail
- Telegram / VK / Yandex buttons use mock login
- Buy/trial uses mock checkout

Admin can edit existing menu tabs and tariffs. Custom HTML is sanitized.

## Production

Menu **34** / `cabinet on` on the panel VPS. URL: `https://DOMAIN_PANEL/lk/`.
Telegram: Login Widget (bot username + token in admin settings). VK and Yandex: OAuth client id/secret.
