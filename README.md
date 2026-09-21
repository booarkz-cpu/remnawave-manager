# Remnawave Manager

Production-РѕСЂРёРµРЅС‚РёСЂРѕРІР°РЅРЅС‹Р№ Bash-РјРµРЅРµРґР¶РµСЂ РґР»СЏ СЂР°Р·РІС‘СЂС‚С‹РІР°РЅРёСЏ Рё РѕР±СЃР»СѓР¶РёРІР°РЅРёСЏ Remnawave РЅР° Debian/Ubuntu.

**РўРµРєСѓС‰Р°СЏ РІРµСЂСЃРёСЏ:** `25.1.6-prod`

## Р‘С‹СЃС‚СЂС‹Р№ СЃС‚Р°СЂС‚

```bash
curl -fsSL https://raw.githubusercontent.com/booarkz-cpu/remnawave-manager/main/remnawave-manager-v25.1.6-prod.sh -o remnawave-manager.sh
chmod +x remnawave-manager.sh
sha256sum remnawave-manager.sh
bash remnawave-manager.sh --dry-run
sudo bash remnawave-manager.sh install single
```

## 25.1.6

Hotfix bootstrap/API РґР»СЏ Р°РєС‚СѓР°Р»СЊРЅРѕРіРѕ Remnawave Panel 3.x:

- РґРѕР±Р°РІР»РµРЅ `X-Remnawave-Client-Type: browser` РІРѕ РІРЅСѓС‚СЂРµРЅРЅРёРµ API-Р·Р°РїСЂРѕСЃС‹ Manager;
- СЌС‚Рѕ СЂР°Р·СЂРµС€Р°РµС‚ admin JWT РІС‹РїРѕР»РЅСЏС‚СЊ API-РІС‹Р·РѕРІС‹, РІРєР»СЋС‡Р°СЏ СЃРѕР·РґР°РЅРёРµ API token, СЃРѕРіР»Р°СЃРЅРѕ С‚РµРєСѓС‰РµРјСѓ `JwtDefaultGuard` backend;
- РєРѕРјР°РЅРґР° `backup` С‚РµРїРµСЂСЊ СЃРѕРѕР±С‰Р°РµС‚ РїРѕРЅСЏС‚РЅСѓСЋ РѕС€РёР±РєСѓ, РµСЃР»Рё backup helper РµС‰С‘ РЅРµ Р±С‹Р» СѓСЃС‚Р°РЅРѕРІР»РµРЅ.

## Runtime

`25.1.6+` РёСЃРїРѕР»СЊР·СѓРµС‚ proxy-aware РІРЅСѓС‚СЂРµРЅРЅРёРµ API-Р·Р°РїСЂРѕСЃС‹:

```text
X-Forwarded-For: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Host: <Panel domain>
Host: <Panel domain>
X-Remnawave-Client-Type: browser
```

## Production status

Static audit: green. Р РµР°Р»СЊРЅС‹Р№ VDS runtime test РѕР±СЏР·Р°С‚РµР»РµРЅ.

## SHA256

```text
e890d9cbbc92b7dad020a3bfb25662979f1fa1f453f62563db28bda1b92b2780  remnawave-manager-v25.1.6-prod.sh
```

РџРѕРґСЂРѕР±РЅРѕСЃС‚Рё: [CHANGELOG.md](CHANGELOG.md).

