# Changelog

## 25.1.9-prod

Firewall/SSH bootstrap hotfix.

- исправлено определение SSH-порта, когда `sshd -T` не возвращает `port`;
- добавлены fallback на `/etc/ssh/sshd_config` и systemd socket activation;
- UFW теперь открывает все обнаруженные SSH-порты перед включением firewall;
- сохранены исправления bootstrap ADMIN/API token из 25.1.7 и 25.1.8.

SHA256:
`04edbee57c6fb0250d6d6c1e8e967553ebc37462a11460e95038068921603086`

## 25.1.8-prod

Bootstrap/API token compatibility hotfix.

- автоматическое имя API token укладывается в ограничение backend `name <= 30`;
- исправлен bootstrap минимального API token для Subscription Page.

SHA256:
`1271774b70e4f4c0b4f8574e25248b665547bc90aac2b6e59ce5d8e2824b46aa`

## 25.1.7-prod

Bootstrap persistence hotfix.

- `ADMIN_PASSWORD` сохраняется в `/opt/remnawave/manager.env` до API login/register;
- повторный запуск после частичного сбоя bootstrap использует тот же пароль.

SHA256:
`6d7920b94652dce6b8ef17a9cbbbfcacaf975a3280294998ce756b73a15d6f4a`
