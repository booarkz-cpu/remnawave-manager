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

Перед production:

1. проверяйте checksum загруженного Manager;
2. тестируйте backup/restore;
3. ограничивайте SSH;
4. ограничивайте `NODE_PORT` только IP Panel;
5. проверяйте сторонние add-ons;
6. фиксируйте upstream версии при требованиях к воспроизводимости.

Официальная документация Remnawave отдельно предупреждает, что Node Port должен быть открыт только для Panel IP. citeturn226976search0

## Уязвимости

Для чувствительных проблем используйте приватный канал владельца проекта. Не публикуйте эксплуатационные детали до исправления.

