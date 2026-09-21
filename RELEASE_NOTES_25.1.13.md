# v25.1.13-prod

Hotfix `repair` для уже установленного 25.1.11.

25.1.12 удалял `/etc/nginx/conf.d/ssl-params.conf` до перезаписи `reality-site.conf`, из‑за этого `nginx -t` падал и 502 не исправлялся.

Скачайте скрипт заново и снова выполните `sudo bash remnawave-manager.sh repair`.
