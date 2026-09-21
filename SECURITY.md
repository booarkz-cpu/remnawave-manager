# Security Policy

## Секреты

Никогда не публикуйте в commit, issue или chat:

- GitHub PAT;
- API token Remnawave;
- Node SECRET_KEY;
- пароль администратора;
- PostgreSQL password;
- age private key;
- Hysteria2 credentials.

## Уязвимости

Для чувствительных проблем используйте приватный канал связи с владельцем репозитория, а не публичный issue. Не публикуйте эксплуатационные детали до исправления.

## Production

- тестируйте backup/restore до обновлений;
- фиксируйте upstream версии, если нужна воспроизводимость;
- проверяйте сторонние add-ons перед запуском;
- по возможности ограничивайте SSH по IP;
- после первичной настройки храните секреты вне `credentials.txt`.
