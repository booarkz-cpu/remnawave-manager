#!/usr/bin/env python3
"""Corgi Lusi user cabinet — stdlib only. No payment-gateway SDKs."""
from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import os
import re
import secrets
import sqlite3
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from http.cookies import SimpleCookie
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA_DIR = Path(os.environ.get("CABINET_DATA", str(ROOT / "data")))
STATIC = ROOT / "static"
DB_PATH = DATA_DIR / "cabinet.sqlite"
LOCK = threading.RLock()

MODE = os.environ.get("CABINET_MODE", "prod")
PREFIX = os.environ.get("CABINET_PREFIX", "").rstrip("/")
HOST = os.environ.get("CABINET_HOST", "127.0.0.1")
PORT = int(os.environ.get("CABINET_PORT", "3050"))
SECRET = os.environ.get("CABINET_SECRET") or secrets.token_hex(32)
ADMIN_PASSWORD = os.environ.get("CABINET_ADMIN_PASSWORD") or os.environ.get("ADMIN_PASSWORD") or ""
RW_API = os.environ.get("REMNAWAVE_API", "http://127.0.0.1:3000/api").rstrip("/")
RW_TOKEN = os.environ.get("REMNAWAVE_TOKEN", "")
RW_HOST = os.environ.get("REMNAWAVE_HOST", "localhost")
DOMAIN_SUB = os.environ.get("DOMAIN_SUB", "sub.example.com")
PUBLIC_URL = os.environ.get("CABINET_PUBLIC_URL", "").rstrip("/")
SQUAD_UUID = os.environ.get("SQUAD_UUID", "")
SESSION_HOURS = 24 * 7
PBKDF2_ROUNDS = 120_000
MAX_BODY = 64 * 1024
LOGIN_WINDOW = 60
LOGIN_MAX = 12
_login_hits: dict[str, list[float]] = {}

EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$")
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9\-]{0,47}$")
USER_RE = re.compile(r"^[A-Za-z][A-Za-z0-9._-]{2,31}$")


def now() -> int:
    return int(time.time())


def json_bytes(obj, code=200):
    raw = json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return code, "application/json; charset=utf-8", raw


def pbkdf2(password: str, salt: str | None = None) -> str:
    salt = salt or secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), PBKDF2_ROUNDS)
    return f"{salt}${dk.hex()}"


def pbkdf2_ok(password: str, stored: str) -> bool:
    if not stored or "$" not in stored:
        return False
    salt, _hex = stored.split("$", 1)
    probe = pbkdf2(password, salt)
    return hmac.compare_digest(probe, stored)


ALLOWED_HTML = {"p", "br", "ul", "ol", "li", "strong", "em", "b", "i", "a", "h2", "h3", "code", "pre", "blockquote"}


def plain_text(text: str, n: int = 80) -> str:
    text = re.sub(r"<[^>]*>", "", text or "")
    return re.sub(r"\s+", " ", text).strip()[:n]


def as_int(value, default: int = 0, lo: int = 0, hi: int = 1_000_000_000) -> int:
    try:
        n = int(value)
    except (TypeError, ValueError):
        n = default
    return max(lo, min(hi, n))


def sanitize_html(text: str) -> str:
    text = text or ""
    text = re.sub(r"(?i)<(script|iframe|object|embed|svg|link|meta|style|form|base)[\s\S]*?</\1>", "", text)
    text = re.sub(r"(?i)</?(script|iframe|object|embed|svg|link|meta|style|form|base)[^>]*>", "", text)
    text = re.sub(r"(?i)on\w+\s*=", "", text)
    text = re.sub(r"(?i)javascript:", "", text)
    text = re.sub(r"(?i)data:", "", text)
    text = re.sub(r"(?i)vbscript:", "", text)

    def _tag(m):
        raw = m.group(0)
        name = re.sub(r"[^a-z0-9]", "", (m.group(1) or "").lower())
        closing = bool(m.group(0).startswith("</"))
        if name not in ALLOWED_HTML:
            return ""
        if closing or name == "br":
            return f"</{name}>" if closing else "<br>"
        if name == "a":
            href = re.search(r'(?i)\bhref\s*=\s*["\']([^"\']+)["\']', raw)
            url = href.group(1) if href else ""
            if not re.match(r"(?i)^(https?:|mailto:|/)", url):
                return "<a>"
            return f'<a href="{url}" rel="noopener noreferrer">'
        return f"<{name}>"

    text = re.sub(r"</?([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>", _tag, text)
    return text[:20000]


def rate_ok(ip: str) -> bool:
    t = time.time()
    if len(_login_hits) > 4000:
        for key in list(_login_hits):
            hits = [x for x in _login_hits[key] if t - x < LOGIN_WINDOW]
            if hits:
                _login_hits[key] = hits
            else:
                _login_hits.pop(key, None)
    bucket = _login_hits.setdefault(ip, [])
    bucket[:] = [x for x in bucket if t - x < LOGIN_WINDOW]
    if len(bucket) >= LOGIN_MAX:
        return False
    bucket.append(t)
    return True


def db() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB_PATH, check_same_thread=False, timeout=10)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys=ON")
    con.execute("PRAGMA journal_mode=WAL")
    con.execute("PRAGMA busy_timeout=5000")
    return con


def query(sql: str, args=(), one=False):
    with LOCK:
        con = db()
        try:
            cur = con.execute(sql, args)
            if sql.lstrip().upper().startswith(("INSERT", "UPDATE", "DELETE", "REPLACE")):
                con.commit()
                return cur.lastrowid
            rows = [dict(r) for r in cur.fetchall()]
            if one:
                return rows[0] if rows else None
            return rows
        finally:
            con.close()


def setting_get(key: str, default: str = "") -> str:
    row = query("SELECT v FROM settings WHERE k=?", (key,), one=True)
    return (row or {}).get("v", default) if row else default


def setting_set(key: str, val: str) -> None:
    query("INSERT INTO settings(k,v) VALUES(?,?) ON CONFLICT(k) DO UPDATE SET v=excluded.v", (key, val))


DEFAULT_INSTRUCTIONS = {
    "android": {
        "ru": "1. Установите v2rayNG или Hiddify из Google Play / GitHub.\n2. Скопируйте ссылку подписки из кабинета.\n3. В приложении: подписка → вставить URL → обновить.\n4. Выберите профиль CorgiLusi и включите VPN.",
        "en": "1. Install v2rayNG or Hiddify.\n2. Copy the subscription URL from the cabinet.\n3. Paste it as a subscription and update.\n4. Select the CorgiLusi profile and connect.",
    },
    "ios": {
        "ru": "1. Установите Streisand или Happ из App Store.\n2. Скопируйте ссылку подписки.\n3. Добавьте подписку по URL, обновите серверы.\n4. Разрешите VPN-профиль в Настройках iOS.",
        "en": "1. Install Streisand or Happ from the App Store.\n2. Copy the subscription URL.\n3. Add it as a subscription and refresh.\n4. Allow the VPN profile in iOS Settings.",
    },
    "tv": {
        "ru": "1. Android TV: Hiddify / v2rayNG из APK.\n2. Apple TV: клиент с поддержкой подписки (Streisand, где доступен).\n3. Вставьте ту же ссылку подписки, что на телефоне.\n4. Выберите Reality или Hysteria2 — что стабильнее в вашей сети.",
        "en": "1. Android TV: Hiddify or v2rayNG APK.\n2. Apple TV: a client that accepts subscription URLs.\n3. Paste the same subscription link as on your phone.\n4. Pick Reality or Hysteria2, whichever is stable.",
    },
    "pc": {
        "ru": "Windows: Hiddify, v2rayN или Nekoray.\nmacOS: Hiddify / Streisand.\nLinux: Hiddify или nekobox.\nИмпортируйте URL подписки, обновите список, включите системный прокси/TUN.",
        "en": "Windows: Hiddify, v2rayN or Nekoray.\nmacOS: Hiddify / Streisand.\nLinux: Hiddify or nekobox.\nImport the subscription URL, update, enable system proxy or TUN.",
    },
}

SEED_TARIFFS = [
    ("trial", "Пробный", "Trial", 3, 50, 2, 0, 1, 10, 1),
    ("start", "Старт", "Start", 30, 100, 2, 199, 0, 20, 1),
    ("plus", "Плюс", "Plus", 90, 500, 4, 499, 0, 30, 1),
    ("max", "Максимум", "Max", 365, 0, 8, 1490, 0, 40, 1),
]

SEED_MENU = [
    ("home", "Обзор", "Overview", "home", "home", 10, 1, ""),
    ("tariffs", "Тарифы", "Plans", "tariffs", "payments", 20, 1, ""),
    ("subscription", "Подписка", "Subscription", "subscription", "link", 30, 1, ""),
    ("instructions", "Подключение", "Setup", "instructions", "devices", 40, 1, ""),
]


def init_db() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with LOCK:
        con = db()
        con.executescript(
            """
            CREATE TABLE IF NOT EXISTS settings (k TEXT PRIMARY KEY, v TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE,
                password_hash TEXT,
                telegram_id TEXT UNIQUE,
                vk_id TEXT UNIQUE,
                yandex_id TEXT UNIQUE,
                display_name TEXT,
                remnawave_uuid TEXT,
                short_uuid TEXT,
                sub_url TEXT,
                created INTEGER NOT NULL
            );
            CREATE TABLE IF NOT EXISTS sessions (
                token TEXT PRIMARY KEY,
                user_id INTEGER,
                admin INTEGER NOT NULL DEFAULT 0,
                exp INTEGER NOT NULL,
                FOREIGN KEY(user_id) REFERENCES users(id)
            );
            CREATE TABLE IF NOT EXISTS tariffs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                slug TEXT UNIQUE NOT NULL,
                title_ru TEXT NOT NULL,
                title_en TEXT NOT NULL,
                days INTEGER NOT NULL,
                traffic_gb INTEGER NOT NULL,
                devices INTEGER NOT NULL,
                price_rub INTEGER NOT NULL,
                is_trial INTEGER NOT NULL DEFAULT 0,
                sort INTEGER NOT NULL DEFAULT 0,
                enabled INTEGER NOT NULL DEFAULT 1
            );
            CREATE TABLE IF NOT EXISTS menu_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                slug TEXT UNIQUE NOT NULL,
                title_ru TEXT NOT NULL,
                title_en TEXT NOT NULL,
                kind TEXT NOT NULL,
                icon TEXT NOT NULL DEFAULT '',
                sort INTEGER NOT NULL DEFAULT 0,
                enabled INTEGER NOT NULL DEFAULT 1,
                body TEXT NOT NULL DEFAULT ''
            );
            CREATE TABLE IF NOT EXISTS orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                tariff_id INTEGER NOT NULL,
                status TEXT NOT NULL,
                amount INTEGER NOT NULL,
                created INTEGER NOT NULL,
                paid_at INTEGER,
                FOREIGN KEY(user_id) REFERENCES users(id),
                FOREIGN KEY(tariff_id) REFERENCES tariffs(id)
            );
            """
        )
        con.commit()
        n = con.execute("SELECT COUNT(*) AS c FROM tariffs").fetchone()["c"]
        if n == 0:
            con.executemany(
                "INSERT INTO tariffs(slug,title_ru,title_en,days,traffic_gb,devices,price_rub,is_trial,sort,enabled) VALUES(?,?,?,?,?,?,?,?,?,?)",
                SEED_TARIFFS,
            )
        n = con.execute("SELECT COUNT(*) AS c FROM menu_items").fetchone()["c"]
        if n == 0:
            con.executemany(
                "INSERT INTO menu_items(slug,title_ru,title_en,kind,icon,sort,enabled,body) VALUES(?,?,?,?,?,?,?,?)",
                SEED_MENU,
            )
        con.commit()
        con.close()
    if not setting_get("brand"):
        setting_set("brand", "Corgi Lusi")
        setting_set("tagline_ru", "Личный кабинет подписки")
        setting_set("tagline_en", "Subscription cabinet")
        setting_set("payment_mode", "mock")
        setting_set("trial_enabled", "1")
        setting_set("oauth_telegram", "0")
        setting_set("oauth_vk", "0")
        setting_set("oauth_yandex", "0")
        setting_set("tg_bot_token", "")
        setting_set("tg_bot_name", "")
        setting_set("vk_client_id", "")
        setting_set("vk_client_secret", "")
        setting_set("ya_client_id", "")
        setting_set("ya_client_secret", "")
        setting_set("instructions", json.dumps(DEFAULT_INSTRUCTIONS, ensure_ascii=False))
        setting_set("public_url", PUBLIC_URL)
    if ADMIN_PASSWORD and not setting_get("admin_password_hash"):
        setting_set("admin_password_hash", pbkdf2(ADMIN_PASSWORD))
    if MODE == "test" and not setting_get("admin_password_hash"):
        setting_set("admin_password_hash", pbkdf2("corgi-test"))


def session_put(user_id: int | None, admin: int, hours: int = SESSION_HOURS) -> str:
    token = secrets.token_urlsafe(32)
    query(
        "INSERT INTO sessions(token,user_id,admin,exp) VALUES(?,?,?,?)",
        (token, user_id, admin, now() + hours * 3600),
    )
    return token


def session_get(token: str | None):
    if not token:
        return None
    query("DELETE FROM sessions WHERE exp < ?", (now(),))
    return query("SELECT * FROM sessions WHERE token=?", (token,), one=True)


def public_base(handler=None) -> str:
    saved = setting_get("public_url") or PUBLIC_URL
    if saved:
        return saved.rstrip("/")
    if handler:
        host = handler.headers.get("X-Forwarded-Host") or handler.headers.get("Host") or f"{HOST}:{PORT}"
        proto = handler.headers.get("X-Forwarded-Proto") or ("http" if MODE == "test" else "https")
        return f"{proto}://{host}{PREFIX}"
    return f"http://127.0.0.1:{PORT}{PREFIX}"


def rw_create_user(local_user: dict, tariff: dict) -> dict:
    """Create or reuse a Remnawave user. Test/mock: synthetic subscription URL."""
    if local_user.get("sub_url") and local_user.get("short_uuid"):
        return {
            "uuid": local_user.get("remnawave_uuid") or "",
            "shortUuid": local_user["short_uuid"],
            "subscriptionUrl": local_user["sub_url"],
        }
    days = max(1, int(tariff.get("days") or 3))
    expire = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now() + days * 86400))
    gb = int(tariff.get("traffic_gb") or 0)
    bytes_ = 0 if gb <= 0 else gb * 1073741824
    devices = int(tariff.get("devices") or 0)
    base = re.sub(r"[^A-Za-z0-9]", "", (local_user.get("email") or "user").split("@")[0])[:10] or "user"
    uname = f"Lk{base}{secrets.token_hex(3)}"[:32]
    if not USER_RE.match(uname):
        uname = f"Lk{secrets.token_hex(6)}"
    if MODE == "test" or not RW_TOKEN:
        short = secrets.token_urlsafe(10).replace("-", "x").replace("_", "y")[:16]
        url = f"https://{DOMAIN_SUB}/{short}"
        return {"uuid": secrets.token_hex(16), "shortUuid": short, "subscriptionUrl": url, "username": uname}
    body = {
        "username": uname,
        "status": "ACTIVE",
        "expireAt": expire,
        "trafficLimitBytes": bytes_,
        "trafficLimitStrategy": "NO_RESET",
    }
    if SQUAD_UUID:
        body["activeInternalSquads"] = [SQUAD_UUID]
    if devices > 0:
        body["hwidDeviceLimit"] = devices
    req = urllib.request.Request(
        f"{RW_API}/users/",
        data=json.dumps(body).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"Bearer {RW_TOKEN}",
            "X-Forwarded-For": "127.0.0.1",
            "X-Forwarded-Proto": "https",
            "X-Forwarded-Host": RW_HOST,
            "Host": RW_HOST,
            "X-Remnawave-Client-Type": "browser",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"remnawave: {exc}") from exc
    resp = data.get("response") or data.get("user") or data
    user = resp.get("user") if isinstance(resp, dict) and "user" in resp else resp
    short = (user or {}).get("shortUuid") or ""
    url = (user or {}).get("subscriptionUrl") or (f"https://{DOMAIN_SUB}/{short}" if short else "")
    return {"uuid": (user or {}).get("uuid") or "", "shortUuid": short, "subscriptionUrl": url, "username": uname}


def attach_sub(user_id: int, payload: dict) -> None:
    query(
        "UPDATE users SET remnawave_uuid=?, short_uuid=?, sub_url=? WHERE id=?",
        (payload.get("uuid") or "", payload.get("shortUuid") or "", payload.get("subscriptionUrl") or "", user_id),
    )


def public_config(handler) -> dict:
    menu = query("SELECT slug,title_ru,title_en,kind,icon,sort FROM menu_items WHERE enabled=1 ORDER BY sort,id")
    tariffs = query(
        "SELECT id,slug,title_ru,title_en,days,traffic_gb,devices,price_rub,is_trial FROM tariffs WHERE enabled=1 ORDER BY sort,id"
    )
    mock = MODE == "test" or setting_get("payment_mode", "mock") == "mock"
    return {
        "brand": setting_get("brand", "Corgi Lusi"),
        "tagline_ru": setting_get("tagline_ru"),
        "tagline_en": setting_get("tagline_en"),
        "prefix": PREFIX,
        "mode": MODE,
        "payment_mode": setting_get("payment_mode", "mock"),
        "mock_payments": mock,
        "trial_enabled": setting_get("trial_enabled", "1") == "1",
        "oauth": {
            "telegram": setting_get("oauth_telegram") == "1" or MODE == "test",
            "vk": setting_get("oauth_vk") == "1" or MODE == "test",
            "yandex": setting_get("oauth_yandex") == "1" or MODE == "test",
            "mock": MODE == "test",
            "tg_bot": setting_get("tg_bot_name"),
        },
        "menu": menu,
        "tariffs": tariffs,
        "public_url": public_base(handler),
    }


def user_public(u: dict) -> dict:
    return {
        "id": u["id"],
        "email": u.get("email"),
        "display_name": u.get("display_name") or (u.get("email") or "user"),
        "has_subscription": bool(u.get("sub_url")),
        "providers": {
            "email": bool(u.get("password_hash")),
            "telegram": bool(u.get("telegram_id")),
            "vk": bool(u.get("vk_id")),
            "yandex": bool(u.get("yandex_id")),
        },
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "CorgiCabinet/1.6.3"

    def log_message(self, fmt, *args):
        path = self.path.split("?")[0]
        sys.stderr.write("%s %s\n" % (self.command, path))

    def _ip(self) -> str:
        return (self.headers.get("X-Forwarded-For") or self.client_address[0] or "").split(",")[0].strip()

    def _path(self) -> str:
        raw = urllib.parse.urlparse(self.path).path
        if PREFIX and (raw == PREFIX or raw.startswith(PREFIX + "/")):
            raw = raw[len(PREFIX) :] or "/"
        if not raw.startswith("/static/") and len(raw) > 1 and raw.endswith("/"):
            raw = raw[:-1]
        return raw or "/"

    def _qs(self) -> dict:
        return dict(urllib.parse.parse_qsl(urllib.parse.urlparse(self.path).query))

    def _cookie(self, name: str) -> str | None:
        jar = SimpleCookie()
        if "Cookie" in self.headers:
            jar.load(self.headers.get("Cookie"))
        if name in jar:
            return jar[name].value
        return None

    def _read_json(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length > MAX_BODY:
            return None, json_bytes({"error": "too_large"}, 413)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            return json.loads(raw.decode() or "{}"), None
        except json.JSONDecodeError:
            return None, json_bytes({"error": "bad_json"}, 400)

    def _send(self, code, ctype, body, extra_headers=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "SAMEORIGIN")
        self.send_header("Referrer-Policy", "same-origin")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'self'; script-src 'self' https://telegram.org; "
            "style-src 'self' 'unsafe-inline'; img-src 'self' data: https://telegram.org; "
            "connect-src 'self'; frame-src https://oauth.telegram.org; base-uri 'none'",
        )
        no_store = ctype.startswith("application/json") or "html" in ctype
        self.send_header("Cache-Control", "no-store" if no_store else "public, max-age=120")
        if extra_headers:
            for k, v in extra_headers:
                self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def _set_cookie(self, name, value, clear=False):
        flags = "HttpOnly; SameSite=Lax; Path=" + (PREFIX or "/")
        if MODE != "test":
            flags += "; Secure"
        if clear:
            return (f"Set-Cookie", f"{name}=; Max-Age=0; {flags}")
        return (f"Set-Cookie", f"{name}={value}; Max-Age={SESSION_HOURS * 3600}; {flags}")

    def _user(self):
        sid = self._cookie("lk_sid")
        row = session_get(sid)
        if not row or row.get("admin") or not row.get("user_id"):
            return None
        return query("SELECT * FROM users WHERE id=?", (row["user_id"],), one=True)

    def _admin(self):
        sid = self._cookie("lk_adm")
        row = session_get(sid)
        return bool(row and row.get("admin"))

    def _html(self, name: str):
        target = (STATIC / name).resolve()
        if target.parent != STATIC.resolve():
            return json_bytes({"error": "not_found"}, 404)
        if not target.is_file():
            return json_bytes({"error": "not_found"}, 404)
        text = target.read_text(encoding="utf-8")
        pfx = PREFIX
        text = text.replace("__PREFIX__", pfx)
        text = text.replace('href="/static/', f'href="{pfx}/static/')
        text = text.replace('src="/static/', f'src="{pfx}/static/')
        text = text.replace('href="/admin"', f'href="{pfx}/admin"')
        text = text.replace('href="/"', f'href="{pfx}/"')
        return 200, "text/html; charset=utf-8", text.encode("utf-8")

    def _file(self, rel: str):
        target = (STATIC / rel).resolve()
        if STATIC.resolve() not in target.parents and target.parent != STATIC.resolve():
            return json_bytes({"error": "not_found"}, 404)
        if not target.is_file():
            return json_bytes({"error": "not_found"}, 404)
        ctype = {
            ".css": "text/css; charset=utf-8",
            ".js": "application/javascript; charset=utf-8",
            ".svg": "image/svg+xml",
            ".html": "text/html; charset=utf-8",
            ".png": "image/png",
            ".woff2": "font/woff2",
        }.get(target.suffix, "application/octet-stream")
        return 200, ctype, target.read_bytes()

    def do_OPTIONS(self):
        self._send(204, "text/plain", b"")

    def _fail(self, exc):
        detail = str(exc)[:200] if MODE == "test" else "error"
        self._send(*json_bytes({"error": "server", "detail": detail}, 500))

    def _path_int(self, index: int):
        parts = [x for x in self._path().split("/") if x]
        try:
            return int(parts[index])
        except (IndexError, ValueError, OverflowError):
            return None

    def do_GET(self):
        try:
            self._dispatch_get()
        except Exception as exc:
            self._fail(exc)

    def do_POST(self):
        try:
            self._dispatch_post()
        except Exception as exc:
            self._fail(exc)

    def do_PUT(self):
        self.do_POST()

    def do_DELETE(self):
        self.do_POST()

    def _dispatch_get(self):
        p = self._path()
        if p in ("/", "/index.html"):
            return self._send(*self._html("index.html"))
        if p in ("/admin", "/admin.html"):
            return self._send(*self._html("admin.html"))
        if p.startswith("/static/"):
            return self._send(*self._file(p[len("/static/") :]))
        if p == "/api/public/config":
            return self._send(*json_bytes(public_config(self)))
        if p == "/api/health":
            return self._send(*json_bytes({"ok": True, "mode": MODE, "payments": "none" if MODE == "test" else setting_get("payment_mode")}))
        if p == "/api/me":
            u = self._user()
            if not u:
                return self._send(*json_bytes({"error": "auth"}, 401))
            return self._send(*json_bytes({"user": user_public(u)}))
        if p == "/api/menu":
            items = query("SELECT slug,title_ru,title_en,kind,icon,sort,body FROM menu_items WHERE enabled=1 ORDER BY sort,id")
            for it in items:
                if it["kind"] != "page":
                    it["body"] = ""
            return self._send(*json_bytes({"items": items}))
        if p == "/api/tariffs":
            rows = query(
                "SELECT id,slug,title_ru,title_en,days,traffic_gb,devices,price_rub,is_trial FROM tariffs WHERE enabled=1 ORDER BY sort,id"
            )
            return self._send(*json_bytes({"tariffs": rows}))
        if p.startswith("/api/pages/"):
            slug = p.split("/")[-1]
            row = query("SELECT slug,title_ru,title_en,kind,body FROM menu_items WHERE slug=? AND enabled=1", (slug,), one=True)
            if not row:
                return self._send(*json_bytes({"error": "not_found"}, 404))
            return self._send(*json_bytes(row))
        if p == "/api/instructions":
            raw = setting_get("instructions") or json.dumps(DEFAULT_INSTRUCTIONS)
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                data = DEFAULT_INSTRUCTIONS
            return self._send(*json_bytes({"devices": data}))
        if p == "/api/subscription":
            u = self._user()
            if not u:
                return self._send(*json_bytes({"error": "auth"}, 401))
            return self._send(
                *json_bytes(
                    {
                        "url": u.get("sub_url") or "",
                        "short_uuid": u.get("short_uuid") or "",
                        "has": bool(u.get("sub_url")),
                    }
                )
            )
        if p.startswith("/api/auth/") and p.endswith("/start"):
            return self._oauth_start(p.split("/")[3])
        if p.startswith("/api/auth/") and p.endswith("/callback"):
            return self._oauth_callback(p.split("/")[3])
        if p.startswith("/api/auth/mock/"):
            return self._oauth_mock(p.split("/")[-1])
        if p == "/api/admin/me":
            if not self._admin():
                return self._send(*json_bytes({"error": "admin"}, 401))
            return self._send(*json_bytes({"admin": True}))
        if p == "/api/admin/settings":
            return self._admin_settings_get()
        if p == "/api/admin/menu":
            if not self._admin():
                return self._send(*json_bytes({"error": "admin"}, 401))
            return self._send(*json_bytes({"items": query("SELECT * FROM menu_items ORDER BY sort,id")}))
        if p == "/api/admin/tariffs":
            if not self._admin():
                return self._send(*json_bytes({"error": "admin"}, 401))
            return self._send(*json_bytes({"tariffs": query("SELECT * FROM tariffs ORDER BY sort,id")}))
        if p == "/api/admin/users":
            if not self._admin():
                return self._send(*json_bytes({"error": "admin"}, 401))
            rows = query(
                "SELECT id,email,display_name,telegram_id,vk_id,yandex_id,short_uuid,created FROM users ORDER BY id DESC LIMIT 200"
            )
            return self._send(*json_bytes({"users": rows}))
        if p == "/api/admin/orders":
            if not self._admin():
                return self._send(*json_bytes({"error": "admin"}, 401))
            rows = query(
                """SELECT o.*, u.email, t.title_ru FROM orders o
                   JOIN users u ON u.id=o.user_id JOIN tariffs t ON t.id=o.tariff_id
                   ORDER BY o.id DESC LIMIT 200"""
            )
            return self._send(*json_bytes({"orders": rows}))
        return self._send(*json_bytes({"error": "not_found"}, 404))

    def _dispatch_post(self):
        p = self._path()
        body, err = self._read_json()
        if err:
            return self._send(*err)
        body = body or {}
        if p == "/api/auth/register":
            return self._register(body)
        if p == "/api/auth/login":
            return self._login(body)
        if p == "/api/auth/logout":
            tok = self._cookie("lk_sid")
            if tok:
                query("DELETE FROM sessions WHERE token=?", (tok,))
            return self._send(*json_bytes({"ok": True}), extra_headers=[self._set_cookie("lk_sid", "", clear=True)])
        if p == "/api/trial":
            return self._trial(body)
        if p == "/api/orders":
            return self._order(body)
        if p.startswith("/api/orders/") and p.endswith("/checkout"):
            oid = self._path_int(2)
            if oid is None:
                return self._send(*json_bytes({"error": "bad_id"}, 400))
            return self._checkout(oid)
        if p == "/api/admin/login":
            return self._admin_login(body)
        if p == "/api/admin/logout":
            tok = self._cookie("lk_adm")
            if tok:
                query("DELETE FROM sessions WHERE token=?", (tok,))
            return self._send(*json_bytes({"ok": True}), extra_headers=[self._set_cookie("lk_adm", "", clear=True)])
        if p == "/api/admin/settings":
            return self._admin_settings_put(body)
        if p == "/api/admin/menu":
            return self._admin_menu_save(body)
        if p.startswith("/api/admin/menu/") and self.command == "DELETE":
            mid = self._path_int(-1)
            if mid is None:
                return self._send(*json_bytes({"error": "bad_id"}, 400))
            return self._admin_menu_del(mid)
        if p == "/api/admin/tariffs":
            return self._admin_tariff_save(body)
        if p.startswith("/api/admin/tariffs/") and self.command == "DELETE":
            tid = self._path_int(-1)
            if tid is None:
                return self._send(*json_bytes({"error": "bad_id"}, 400))
            return self._admin_tariff_del(tid)
        if p.startswith("/api/admin/orders/") and p.endswith("/paid"):
            oid = self._path_int(3)
            if oid is None:
                return self._send(*json_bytes({"error": "bad_id"}, 400))
            return self._admin_mark_paid(oid)
        if p == "/api/admin/instructions":
            return self._admin_instructions(body)
        return self._send(*json_bytes({"error": "not_found"}, 404))

    def _register(self, body):
        if not rate_ok(self._ip()):
            return self._send(*json_bytes({"error": "rate"}, 429))
        email = str(body.get("email") or "").strip().lower()
        password = str(body.get("password") or "")
        name = str(body.get("name") or email.split("@")[0])[:64]
        if not EMAIL_RE.match(email) or len(password) < 8:
            return self._send(*json_bytes({"error": "invalid"}, 400))
        if query("SELECT id FROM users WHERE email=?", (email,), one=True):
            return self._send(*json_bytes({"error": "exists"}, 409))
        try:
            uid = query(
                "INSERT INTO users(email,password_hash,display_name,created) VALUES(?,?,?,?)",
                (email, pbkdf2(password), name, now()),
            )
        except sqlite3.IntegrityError:
            return self._send(*json_bytes({"error": "exists"}, 409))
        tok = session_put(uid, 0)
        u = query("SELECT * FROM users WHERE id=?", (uid,), one=True)
        return self._send(*json_bytes({"user": user_public(u)}), extra_headers=[self._set_cookie("lk_sid", tok)])

    def _login(self, body):
        if not rate_ok(self._ip()):
            return self._send(*json_bytes({"error": "rate"}, 429))
        email = str(body.get("email") or "").strip().lower()
        password = str(body.get("password") or "")
        u = query("SELECT * FROM users WHERE email=?", (email,), one=True)
        if not u or not pbkdf2_ok(password, u.get("password_hash") or ""):
            return self._send(*json_bytes({"error": "credentials"}, 401))
        tok = session_put(u["id"], 0)
        return self._send(*json_bytes({"user": user_public(u)}), extra_headers=[self._set_cookie("lk_sid", tok)])

    def _oauth_mock(self, provider):
        if MODE != "test":
            return self._send(*json_bytes({"error": "forbidden"}, 403))
        if provider not in ("telegram", "vk", "yandex"):
            return self._send(*json_bytes({"error": "provider"}, 400))
        ext_id = f"mock-{provider}"
        col = {"telegram": "telegram_id", "vk": "vk_id", "yandex": "yandex_id"}[provider]
        email = f"{provider}.mock@cabinet.local"
        u = query(f"SELECT * FROM users WHERE {col}=?", (ext_id,), one=True)
        if not u:
            u = query("SELECT * FROM users WHERE email=?", (email,), one=True)
        if not u:
            try:
                uid = query(
                    f"INSERT INTO users(email,{col},display_name,created) VALUES(?,?,?,?)",
                    (email, ext_id, provider.title(), now()),
                )
            except sqlite3.IntegrityError:
                row = query(f"SELECT * FROM users WHERE {col}=?", (ext_id,), one=True) or query(
                    "SELECT * FROM users WHERE email=?", (email,), one=True
                )
                if not row:
                    return self._send(*json_bytes({"error": "exists"}, 409))
                uid = row["id"]
        else:
            uid = u["id"]
            query(f"UPDATE users SET {col}=? WHERE id=?", (ext_id, uid))
        tok = session_put(uid, 0)
        loc = PREFIX + "/#/"
        hdrs = [self._set_cookie("lk_sid", tok), ("Location", loc)]
        self._send(302, "text/plain", b"ok", extra_headers=hdrs)

    def _oauth_start(self, provider):
        if MODE == "test":
            return self._oauth_mock(provider)
        redirect = public_base(self) + f"/api/auth/{provider}/callback"
        state = secrets.token_urlsafe(16)
        setting_set(f"oauth_state_{state}", str(now() + 600))
        if provider == "vk":
            cid = setting_get("vk_client_id")
            if not cid:
                return self._send(*json_bytes({"error": "not_configured"}, 400))
            url = "https://oauth.vk.com/authorize?" + urllib.parse.urlencode(
                {"client_id": cid, "redirect_uri": redirect, "scope": "email", "response_type": "code", "state": state}
            )
        elif provider == "yandex":
            cid = setting_get("ya_client_id")
            if not cid:
                return self._send(*json_bytes({"error": "not_configured"}, 400))
            url = "https://oauth.yandex.ru/authorize?" + urllib.parse.urlencode(
                {"client_id": cid, "redirect_uri": redirect, "response_type": "code", "state": state}
            )
        elif provider == "telegram":
            return self._send(*json_bytes({"error": "use_widget"}, 400))
        else:
            return self._send(*json_bytes({"error": "provider"}, 400))
        self._send(302, "text/plain", b"", extra_headers=[("Location", url)])

    def _oauth_callback(self, provider):
        qs = self._qs()
        if MODE == "test":
            return self._oauth_mock(provider)
        if provider == "telegram":
            return self._telegram_widget(qs)
        state = qs.get("state", "")
        exp = setting_get(f"oauth_state_{state}")
        if not exp or int(exp or 0) < now():
            return self._send(*json_bytes({"error": "state"}, 400))
        query("DELETE FROM settings WHERE k=?", (f"oauth_state_{state}",))
        code = qs.get("code", "")
        redirect = public_base(self) + f"/api/auth/{provider}/callback"
        ext_id, email, name = "", "", provider
        try:
            if provider == "vk":
                tok_url = "https://oauth.vk.com/access_token?" + urllib.parse.urlencode(
                    {
                        "client_id": setting_get("vk_client_id"),
                        "client_secret": setting_get("vk_client_secret"),
                        "redirect_uri": redirect,
                        "code": code,
                    }
                )
                with urllib.request.urlopen(tok_url, timeout=15) as resp:
                    data = json.loads(resp.read().decode())
                ext_id = str(data.get("user_id") or "")
                email = (data.get("email") or f"vk{ext_id}@vk.local").lower()
                name = f"VK {ext_id}"
            elif provider == "yandex":
                req = urllib.request.Request(
                    "https://oauth.yandex.ru/token",
                    data=urllib.parse.urlencode(
                        {
                            "grant_type": "authorization_code",
                            "code": code,
                            "client_id": setting_get("ya_client_id"),
                            "client_secret": setting_get("ya_client_secret"),
                        }
                    ).encode(),
                    method="POST",
                )
                with urllib.request.urlopen(req, timeout=15) as resp:
                    data = json.loads(resp.read().decode())
                access = data.get("access_token") or ""
                info_req = urllib.request.Request(
                    "https://login.yandex.ru/info?format=json",
                    headers={"Authorization": f"OAuth {access}"},
                )
                with urllib.request.urlopen(info_req, timeout=15) as resp:
                    info = json.loads(resp.read().decode())
                ext_id = str(info.get("id") or "")
                emails = info.get("emails") or []
                email = (info.get("default_email") or (emails[0] if emails else f"ya{ext_id}@yandex.local")).lower()
                name = info.get("real_name") or info.get("login") or "Yandex"
            else:
                return self._send(*json_bytes({"error": "provider"}, 400))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError) as exc:
            return self._send(*json_bytes({"error": "oauth", "detail": str(exc)[:120]}, 502))
        col = {"vk": "vk_id", "yandex": "yandex_id", "telegram": "telegram_id"}[provider]
        u = query(f"SELECT * FROM users WHERE {col}=?", (ext_id,), one=True) or query(
            "SELECT * FROM users WHERE email=?", (email,), one=True
        )
        if not u:
            try:
                uid = query(
                    f"INSERT INTO users(email,{col},display_name,created) VALUES(?,?,?,?)",
                    (email, ext_id, name[:64], now()),
                )
            except sqlite3.IntegrityError:
                row = query(f"SELECT * FROM users WHERE {col}=?", (ext_id,), one=True) or query(
                    "SELECT * FROM users WHERE email=?", (email,), one=True
                )
                if not row:
                    return self._send(*json_bytes({"error": "exists"}, 409))
                uid = row["id"]
        else:
            uid = u["id"]
            query(f"UPDATE users SET {col}=?, email=COALESCE(email,?) WHERE id=?", (ext_id, email, uid))
        tok = session_put(uid, 0)
        self._send(302, "text/plain", b"ok", extra_headers=[self._set_cookie("lk_sid", tok), ("Location", PREFIX + "/#/")])

    def _telegram_widget(self, qs):
        token = setting_get("tg_bot_token")
        if not token:
            return self._send(*json_bytes({"error": "not_configured"}, 400))
        check = qs.get("hash") or ""
        pairs = {k: v for k, v in qs.items() if k != "hash"}
        data_check = "\n".join(f"{k}={pairs[k]}" for k in sorted(pairs))
        secret = hashlib.sha256(token.encode()).digest()
        digest = hmac.new(secret, data_check.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(digest, check):
            return self._send(*json_bytes({"error": "telegram_hash"}, 401))
        try:
            auth_age = abs(now() - int(pairs.get("auth_date") or 0))
        except ValueError:
            auth_age = 10**9
        if auth_age > 86400:
            return self._send(*json_bytes({"error": "telegram_stale"}, 401))
        ext_id = str(pairs.get("id") or "")
        name = pairs.get("username") or pairs.get("first_name") or "Telegram"
        email = f"tg{ext_id}@telegram.local"
        u = query("SELECT * FROM users WHERE telegram_id=?", (ext_id,), one=True)
        if not u:
            try:
                uid = query(
                    "INSERT INTO users(email,telegram_id,display_name,created) VALUES(?,?,?,?)",
                    (email, ext_id, name[:64], now()),
                )
            except sqlite3.IntegrityError:
                row = query("SELECT * FROM users WHERE telegram_id=?", (ext_id,), one=True)
                if not row:
                    return self._send(*json_bytes({"error": "exists"}, 409))
                uid = row["id"]
        else:
            uid = u["id"]
        tok = session_put(uid, 0)
        self._send(302, "text/plain", b"ok", extra_headers=[self._set_cookie("lk_sid", tok), ("Location", PREFIX + "/#/")])

    def _grant(self, user, tariff, amount: int, status: str):
        oid = query(
            "INSERT INTO orders(user_id,tariff_id,status,amount,created,paid_at) VALUES(?,?,?,?,?,?)",
            (user["id"], tariff["id"], status, amount, now(), now() if status == "paid" else None),
        )
        if status != "paid":
            return oid, None
        payload = rw_create_user(user, tariff)
        attach_sub(user["id"], payload)
        return oid, payload

    def _trial(self, body):
        u = self._user()
        if not u:
            return self._send(*json_bytes({"error": "auth"}, 401))
        if setting_get("trial_enabled", "1") != "1":
            return self._send(*json_bytes({"error": "trial_off"}, 400))
        paid = query("SELECT id FROM orders WHERE user_id=? AND status='paid'", (u["id"],), one=True)
        if paid:
            return self._send(*json_bytes({"error": "already"}, 409))
        tid = as_int(body.get("tariff_id"), 0) or None
        extra = " AND id=?" if tid else ""
        args = (tid,) if tid else ()
        tariff = query(
            f"SELECT * FROM tariffs WHERE enabled=1 AND is_trial=1{extra} ORDER BY sort LIMIT 1",
            args,
            one=True,
        )
        if not tariff:
            return self._send(*json_bytes({"error": "no_trial"}, 400))
        try:
            oid, payload = self._grant(u, tariff, 0, "paid")
        except RuntimeError as exc:
            return self._send(*json_bytes({"error": "remnawave", "detail": str(exc)[:160]}, 502))
        u2 = query("SELECT * FROM users WHERE id=?", (u["id"],), one=True)
        return self._send(*json_bytes({"order_id": oid, "subscription": payload, "user": user_public(u2)}))

    def _order(self, body):
        u = self._user()
        if not u:
            return self._send(*json_bytes({"error": "auth"}, 401))
        tid = as_int(body.get("tariff_id"), 0)
        tariff = query("SELECT * FROM tariffs WHERE id=? AND enabled=1", (tid,), one=True)
        if not tariff:
            return self._send(*json_bytes({"error": "tariff"}, 404))
        if tariff["is_trial"]:
            return self._trial({"tariff_id": tid})
        oid, _ = self._grant(u, tariff, int(tariff["price_rub"]), "pending")
        return self._send(*json_bytes({"order_id": oid, "amount": tariff["price_rub"], "payment_mode": setting_get("payment_mode", "mock")}))

    def _checkout(self, order_id: int):
        u = self._user()
        if not u:
            return self._send(*json_bytes({"error": "auth"}, 401))
        order = query("SELECT * FROM orders WHERE id=? AND user_id=?", (order_id, u["id"]), one=True)
        if not order:
            return self._send(*json_bytes({"error": "order"}, 404))
        if order["status"] == "paid":
            return self._send(*json_bytes({"ok": True, "url": u.get("sub_url")}))
        mode = setting_get("payment_mode", "mock")
        # Test script and default production: no payment-gateway SDKs.
        if MODE != "test" and mode == "manual":
            return self._send(*json_bytes({"status": "pending", "hint": "admin"}))
        tariff = query("SELECT * FROM tariffs WHERE id=?", (order["tariff_id"],), one=True)
        try:
            payload = rw_create_user(u, tariff)
        except RuntimeError as exc:
            return self._send(*json_bytes({"error": "remnawave", "detail": str(exc)[:160]}, 502))
        attach_sub(u["id"], payload)
        query("UPDATE orders SET status='paid', paid_at=? WHERE id=?", (now(), order_id))
        return self._send(*json_bytes({"ok": True, "subscription": payload, "gateway": "none"}))

    def _admin_login(self, body):
        if not rate_ok(self._ip()):
            return self._send(*json_bytes({"error": "rate"}, 429))
        password = str(body.get("password") or "")
        stored = setting_get("admin_password_hash")
        if not stored or not pbkdf2_ok(password, stored):
            return self._send(*json_bytes({"error": "credentials"}, 401))
        tok = session_put(None, 1)
        return self._send(*json_bytes({"admin": True}), extra_headers=[self._set_cookie("lk_adm", tok)])

    def _admin_settings_get(self):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        keys = [
            "brand",
            "tagline_ru",
            "tagline_en",
            "payment_mode",
            "trial_enabled",
            "oauth_telegram",
            "oauth_vk",
            "oauth_yandex",
            "tg_bot_name",
            "public_url",
        ]
        data = {k: setting_get(k) for k in keys}
        data["vk_client_id"] = setting_get("vk_client_id")
        data["ya_client_id"] = setting_get("ya_client_id")
        data["has_tg_bot_token"] = bool(setting_get("tg_bot_token"))
        data["has_vk_secret"] = bool(setting_get("vk_client_secret"))
        data["has_ya_secret"] = bool(setting_get("ya_client_secret"))
        data["has_remnawave_token"] = bool(RW_TOKEN)
        return self._send(*json_bytes(data))

    def _admin_settings_put(self, body):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        allowed = {
            "brand",
            "tagline_ru",
            "tagline_en",
            "payment_mode",
            "trial_enabled",
            "oauth_telegram",
            "oauth_vk",
            "oauth_yandex",
            "tg_bot_name",
            "tg_bot_token",
            "vk_client_id",
            "vk_client_secret",
            "ya_client_id",
            "ya_client_secret",
            "public_url",
        }
        for k, v in body.items():
            if k not in allowed:
                continue
            if k in ("brand", "tagline_ru", "tagline_en", "tg_bot_name"):
                v = plain_text(str(v), 200)
            if k == "payment_mode" and str(v) not in ("mock", "manual"):
                continue
            if k.endswith("token") or k.endswith("secret"):
                if not str(v):
                    continue
            setting_set(k, str(v)[:2000])
        if body.get("admin_password"):
            pw = str(body["admin_password"])
            if len(pw) >= 8:
                setting_set("admin_password_hash", pbkdf2(pw))
        return self._send(*json_bytes({"ok": True}))

    def _admin_menu_save(self, body):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        slug = str(body.get("slug") or "").strip().lower()
        if not SLUG_RE.match(slug):
            return self._send(*json_bytes({"error": "slug"}, 400))
        kind = str(body.get("kind") or "page")
        if kind not in ("home", "tariffs", "subscription", "instructions", "page"):
            return self._send(*json_bytes({"error": "kind"}, 400))
        fields = (
            slug,
            plain_text(str(body.get("title_ru") or slug), 80) or slug,
            plain_text(str(body.get("title_en") or slug), 80) or slug,
            kind,
            str(body.get("icon") or "")[:32],
            as_int(body.get("sort"), 50, 0, 10000),
            1 if body.get("enabled", 1) else 0,
            sanitize_html(str(body.get("body") or "")),
        )
        existing = query("SELECT id FROM menu_items WHERE slug=?", (slug,), one=True)
        if existing and not body.get("id"):
            body["id"] = existing["id"]
        if body.get("id"):
            query(
                "UPDATE menu_items SET slug=?,title_ru=?,title_en=?,kind=?,icon=?,sort=?,enabled=?,body=? WHERE id=?",
                fields + (as_int(body["id"]),),
            )
            mid = as_int(body["id"])
        else:
            try:
                mid = query(
                    "INSERT INTO menu_items(slug,title_ru,title_en,kind,icon,sort,enabled,body) VALUES(?,?,?,?,?,?,?,?)",
                    fields,
                )
            except sqlite3.IntegrityError:
                return self._send(*json_bytes({"error": "exists"}, 409))
        return self._send(*json_bytes({"id": mid, "ok": True}))

    def _admin_menu_del(self, mid: int):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        row = query("SELECT kind FROM menu_items WHERE id=?", (mid,), one=True)
        if not row:
            return self._send(*json_bytes({"error": "not_found"}, 404))
        if row["kind"] != "page":
            return self._send(*json_bytes({"error": "builtin"}, 400))
        query("DELETE FROM menu_items WHERE id=?", (mid,))
        return self._send(*json_bytes({"ok": True}))

    def _admin_tariff_save(self, body):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        slug = str(body.get("slug") or "").strip().lower()
        if not SLUG_RE.match(slug):
            return self._send(*json_bytes({"error": "slug"}, 400))
        fields = (
            slug,
            plain_text(str(body.get("title_ru") or slug), 80) or slug,
            plain_text(str(body.get("title_en") or slug), 80) or slug,
            as_int(body.get("days") or 30, 30, 1, 3650),
            as_int(body.get("traffic_gb"), 0, 0, 1_000_000),
            as_int(body.get("devices"), 0, 0, 1000),
            as_int(body.get("price_rub"), 0, 0, 10_000_000),
            1 if body.get("is_trial") else 0,
            as_int(body.get("sort"), 50, 0, 10000),
            1 if body.get("enabled", 1) else 0,
        )
        if body.get("id"):
            query(
                "UPDATE tariffs SET slug=?,title_ru=?,title_en=?,days=?,traffic_gb=?,devices=?,price_rub=?,is_trial=?,sort=?,enabled=? WHERE id=?",
                fields + (as_int(body["id"]),),
            )
            tid = as_int(body["id"])
        else:
            try:
                tid = query(
                    "INSERT INTO tariffs(slug,title_ru,title_en,days,traffic_gb,devices,price_rub,is_trial,sort,enabled) VALUES(?,?,?,?,?,?,?,?,?,?)",
                    fields,
                )
            except sqlite3.IntegrityError:
                return self._send(*json_bytes({"error": "exists"}, 409))
        return self._send(*json_bytes({"id": tid, "ok": True}))

    def _admin_tariff_del(self, tid: int):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        used = query("SELECT id FROM orders WHERE tariff_id=? LIMIT 1", (tid,), one=True)
        if used:
            query("UPDATE tariffs SET enabled=0 WHERE id=?", (tid,))
            return self._send(*json_bytes({"ok": True, "disabled": True}))
        query("DELETE FROM tariffs WHERE id=?", (tid,))
        return self._send(*json_bytes({"ok": True}))

    def _admin_mark_paid(self, oid: int):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        order = query("SELECT * FROM orders WHERE id=?", (oid,), one=True)
        if not order:
            return self._send(*json_bytes({"error": "order"}, 404))
        user = query("SELECT * FROM users WHERE id=?", (order["user_id"],), one=True)
        tariff = query("SELECT * FROM tariffs WHERE id=?", (order["tariff_id"],), one=True)
        if not user or not tariff:
            return self._send(*json_bytes({"error": "missing"}, 404))
        try:
            payload = rw_create_user(user, tariff)
        except RuntimeError as exc:
            return self._send(*json_bytes({"error": "remnawave", "detail": str(exc)[:160]}, 502))
        attach_sub(user["id"], payload)
        query("UPDATE orders SET status='paid', paid_at=? WHERE id=?", (now(), oid))
        return self._send(*json_bytes({"ok": True, "subscription": payload}))

    def _admin_instructions(self, body):
        if not self._admin():
            return self._send(*json_bytes({"error": "admin"}, 401))
        current = json.loads(setting_get("instructions") or json.dumps(DEFAULT_INSTRUCTIONS))
        for dev in ("android", "ios", "tv", "pc"):
            if dev in body and isinstance(body[dev], dict):
                current.setdefault(dev, {})
                for lang in ("ru", "en"):
                    if lang in body[dev]:
                        current[dev][lang] = str(body[dev][lang])[:8000]
        setting_set("instructions", json.dumps(current, ensure_ascii=False))
        return self._send(*json_bytes({"ok": True}))


def main():
    global HOST, PORT, MODE, PREFIX, SECRET, ADMIN_PASSWORD
    parser = argparse.ArgumentParser(description="Corgi Lusi user cabinet")
    parser.add_argument("--host", default=HOST)
    parser.add_argument("--port", type=int, default=PORT)
    parser.add_argument("--test", action="store_true", help="Mock payments and OAuth; no payment gateways")
    parser.add_argument("--prefix", default=PREFIX)
    args = parser.parse_args()
    HOST, PORT, PREFIX = args.host, args.port, args.prefix.rstrip("/")
    if args.test:
        MODE = "test"
        os.environ["CABINET_MODE"] = "test"
        if not ADMIN_PASSWORD:
            ADMIN_PASSWORD = "corgi-test"
    os.environ.setdefault("CABINET_MODE", MODE)
    init_db()
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"cabinet {MODE} http://{HOST}:{PORT}{PREFIX}/  admin=/admin  payments=off", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.shutdown()


if __name__ == "__main__":
    main()
