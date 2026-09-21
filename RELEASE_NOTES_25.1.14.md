# v25.1.14-prod

Не скачивайте скрипт с `raw.githubusercontent.com/main`: CDN отдаёт кэш 25.1.12 (`45e5029a…`), и `repair` снова падает на `ssl-params.conf`.

Берите релиз:

https://github.com/booarkz-cpu/remnawave-manager/releases/download/v25.1.14-prod/remnawave-manager.sh

`repair` сразу восстанавливает stub `ssl-params.conf`, затем переписывает vhosts и сайт Corgi Lusi. В логе должно быть `repair: Remnawave Manager 25.1.14-prod`.
