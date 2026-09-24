# Security

Never commit secrets to Git.

Sensitive values include:

- API tokens;
- database passwords;
- `SECRET_KEY`;
- Telegram Bot Token;
- age private keys;
- TLS private keys;
- `.env` secrets;
- `/opt/remnawave/credentials.txt`.

Before committing:

```bash
git status
git diff -- docs/wiki
```

Make sure no credentials are included.

Treat backups as sensitive because they can contain credentials and configuration secrets.
