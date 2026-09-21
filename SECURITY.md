# Security Policy

## Секреты

Никогда не публикуйте в Git, issue, PR или chat:

- GitHub PAT;
- Remnawave API token;
- JWT;
- Node `SECRET_KEY`;
- PostgreSQL password;
- age private key;
- Hysteria2 password;
- Telegram bot token.

## Production

- проверяйте SHA256;
- тестируйте backup/restore;
- ограничивайте SSH;
- ограничивайте Node port только Panel IP;
- проверяйте сторонние add-ons;
- фиксируйте upstream версии для воспроизводимости.

## Уязвимости

Для чувствительных проблем используйте приватный канал владельца проекта. Не публикуйте эксплуатационные детали до исправления.

