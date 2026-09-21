# v1.5.0

Пункты **28–32** (1–27 на месте): пользователи, управление нодой, Telegram + rclone backup, сертификаты, UFW/ADMIN_IP. Пункт **23** показывает логин панели только по слову SHOW (не в лог). После **25** на панели — чеклист apply на ноде. В шапке — ближайший срок Let’s Encrypt.

```bash
bash remnawave-manager.sh self-update
bash remnawave-manager.sh --version
# remnawave-manager 1.5.0
```

```bash
curl -fL --retry 5 --retry-all-errors \
  https://cdn.jsdelivr.net/gh/booarkz-cpu/remnawave-manager@v1.5.0/remnawave-manager.sh \
  -o remnawave-manager.sh
# sha256: 72c9cb8ca9ac35bb03b596bb32d68ff507c43f36992d1ee615962da3f44bacdb
```

SHA256: `72c9cb8ca9ac35bb03b596bb32d68ff507c43f36992d1ee615962da3f44bacdb`
