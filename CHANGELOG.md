# Changelog

## 25.1.10-prod

Automatic full OS update during installation.

- runs `apt-get update` before installing dependencies;
- runs `dpkg --configure -a`;
- runs `apt-get -f install -y`;
- runs `apt-get full-upgrade -y`;
- runs `apt-get autoremove --purge -y` and `apt-get autoclean -qq`;
- does not reboot automatically; reports `/var/run/reboot-required` when present.

SHA256:
`97a9a6cdfb5d203c35e43eee87ef8977ec34e3054a9fa5ca64dfc031fedb925`

## 25.1.9-prod

Firewall/SSH bootstrap hotfix.

- fixed SSH port detection when `sshd -T` returns no `port`;
- added fallbacks for `/etc/ssh/sshd_config` and systemd socket activation;
- UFW opens all detected SSH ports before enabling the firewall;
- preserved bootstrap ADMIN/API token fixes from 25.1.7 and 25.1.8.

SHA256:
`04edbee57c6fb0250d6d6c1e8e967553ebc37462a11460e95038068921603086`

## 25.1.8-prod

Bootstrap/API token compatibility hotfix.

- automatic API token name stays within backend `name <= 30`;
- fixed bootstrap of the minimal API token for Subscription Page.

SHA256:
`1271774b70e4f4c0b4f8574e25248b665547bc90aac2b6e59ce5d8e2824b46aa`

## 25.1.7-prod

Bootstrap persistence hotfix.

- `ADMIN_PASSWORD` is saved to `/opt/remnawave/manager.env` before API login/register;
- reruns after a partial bootstrap use the same password.

SHA256:
`6d7920b94652dce6b8ef17a9cbbbfcacaf975a3280294998ce756b73a15d6f4a`
