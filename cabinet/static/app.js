const S = {
  lang: localStorage.getItem("lk_lang") || "ru",
  cfg: null,
  me: null,
};

const T = {
  ru: {
    login: "Вход", logout: "Выход", register: "Регистрация", email: "Email",
    password: "Пароль (от 8 символов)", name: "Имя", go: "Войти", create: "Создать аккаунт",
    tariffs: "Тарифы", buy: "Купить", trial: "Пробный период", sub: "Ссылка подписки",
    copy: "Копировать", none: "Подписки ещё нет — выберите тариф.",
    help: "Инструкция", android: "Android", ios: "iOS", tv: "Телевизор", pc: "Компьютер",
    oauth_tg: "Войти через Telegram", oauth_vk: "Войти через ВКонтакте",
    oauth_ya: "Войти через Яндекс", mock: "тест без шлюзов",
    pay: "Оплатить без платёжного шлюза", pending: "Ждёт подтверждения администратора",
    hero: "Ваш личный кабинет подписки",
    lead: "Тарифы, пробный период, ссылка и инструкции для Android, iOS, ТВ и ПК.",
    err: "Ошибка", copied: "Скопировано",
  },
  en: {
    login: "Sign in", logout: "Sign out", register: "Register", email: "Email",
    password: "Password (8+ chars)", name: "Name", go: "Sign in", create: "Create account",
    tariffs: "Plans", buy: "Buy", trial: "Start trial", sub: "Subscription URL",
    copy: "Copy", none: "No subscription yet — pick a plan.",
    help: "Setup", android: "Android", ios: "iOS", tv: "TV", pc: "Computer",
    oauth_tg: "Continue with Telegram", oauth_vk: "Continue with VK",
    oauth_ya: "Continue with Yandex", mock: "test, no payment gateways",
    pay: "Pay without a payment gateway", pending: "Waiting for admin confirmation",
    hero: "Your subscription cabinet",
    lead: "Plans, trial, subscription link and setup for Android, iOS, TV and PC.",
    err: "Error", copied: "Copied",
  },
};

const t = (k) => (T[S.lang] || T.ru)[k] || k;
const $ = (s) => document.querySelector(s);
const app = () => $("#app");
const BASE = document.body.getAttribute("data-prefix") || "";
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
}[c]));

async function api(path, opt = {}) {
  const res = await fetch(BASE + path, {
    credentials: "same-origin",
    headers: { "Content-Type": "application/json", ...(opt.headers || {}) },
    ...opt,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw Object.assign(new Error(data.error || "error"), { data, status: res.status });
  return data;
}

function title(item) {
  return S.lang === "en" ? item.title_en : item.title_ru;
}

function nav() {
  const n = $("#nav");
  if (!S.cfg) return;
  n.innerHTML = (S.cfg.menu || []).map((m) =>
    `<a href="#/${esc(m.slug)}" data-slug="${esc(m.slug)}">${esc(title(m))}</a>`).join("");
  $("#brand").textContent = S.cfg.brand || "Corgi Lusi";
  $("#langBtn").textContent = S.lang === "ru" ? "EN" : "RU";
  $("#authBtn").textContent = S.me ? t("logout") : t("login");
}

async function refreshCfg() {
  try {
    S.cfg = await api("/api/public/config");
    nav();
  } catch (_) {}
}

async function route() {
  await refreshCfg();
  const hash = (location.hash || "#/home").replace(/^#\/?/, "") || "home";
  const slug = hash.split("/")[0] || "home";
  document.querySelectorAll("#nav a").forEach((a) => a.classList.toggle("active", a.dataset.slug === slug));
  const item = (S.cfg.menu || []).find((m) => m.slug === slug);
  const kind = item ? item.kind : slug;
  if (slug === "login") return renderAuth("login");
  if (slug === "register") return renderAuth("register");
  if (kind === "tariffs") return renderTariffs();
  if (kind === "subscription") return renderSub();
  if (kind === "instructions") return renderHelp();
  if (kind === "page") return renderPage(slug);
  return renderHome();
}

function renderHome() {
  const tag = S.lang === "ru" ? (S.cfg.tagline_ru || "") : (S.cfg.tagline_en || "");
  app().innerHTML = `
    <section class="hero">
      <div>
        <p class="muted">${esc(tag)}</p>
        <h1>${t("hero")}</h1>
        <p class="muted">${t("lead")}</p>
        <p><a class="btn" href="#/tariffs">${t("tariffs")}</a></p>
      </div>
      <article class="card glass">
        <h2>${esc(S.me ? S.me.display_name : t("login"))}</h2>
        <p class="muted">${S.me && S.me.has_subscription ? t("sub") : t("none")}</p>
      </article>
    </section>`;
}

function oauthButtons() {
  const o = S.cfg.oauth || {};
  const box = $("#oauth");
  if (!box) return;
  box.innerHTML = "";
  const addMock = (provider, label) => {
    const a = document.createElement("a");
    a.href = `${BASE}/api/auth/mock/${provider}`;
    a.textContent = `${label} · ${t("mock")}`;
    box.appendChild(a);
  };
  if (o.telegram && o.mock) addMock("telegram", t("oauth_tg"));
  else if (o.telegram && o.tg_bot) {
    const s = document.createElement("script");
    s.async = true;
    s.src = "https://telegram.org/js/telegram-widget.js?22";
    s.setAttribute("data-telegram-login", o.tg_bot);
    s.setAttribute("data-size", "large");
    s.setAttribute("data-userpic", "false");
    s.setAttribute("data-request-access", "write");
    s.setAttribute("data-auth-url", `${location.origin}${BASE}/api/auth/telegram/callback`);
    box.appendChild(s);
  }
  if (o.vk) {
    if (o.mock) addMock("vk", t("oauth_vk"));
    else {
      const a = document.createElement("a");
      a.href = `${BASE}/api/auth/vk/start`;
      a.textContent = t("oauth_vk");
      box.appendChild(a);
    }
  }
  if (o.yandex) {
    if (o.mock) addMock("yandex", t("oauth_ya"));
    else {
      const a = document.createElement("a");
      a.href = `${BASE}/api/auth/yandex/start`;
      a.textContent = t("oauth_ya");
      box.appendChild(a);
    }
  }
}

function renderAuth(mode) {
  app().innerHTML = `
    <article class="card glass" style="max-width:420px;margin:40px auto">
      <h1>${mode === "login" ? t("login") : t("register")}</h1>
      <form id="f">
        ${mode === "register" ? `<label>${t("name")}</label><input name="name">` : ""}
        <label>${t("email")}</label><input name="email" type="email" required>
        <label>${t("password")}</label><input name="password" type="password" minlength="8" required>
        <p class="err" id="e"></p>
        <button class="btn" type="submit">${mode === "login" ? t("go") : t("create")}</button>
      </form>
      <p><a href="#/${mode === "login" ? "register" : "login"}">${mode === "login" ? t("register") : t("login")}</a></p>
      <div class="oauth" id="oauth"></div>
    </article>`;
  oauthButtons();
  $("#f").onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = Object.fromEntries(new FormData(ev.target));
    try {
      S.me = (await api(mode === "login" ? "/api/auth/login" : "/api/auth/register", { method: "POST", body: JSON.stringify(fd) })).user;
      nav(); location.hash = "#/";
    } catch (err) { $("#e").textContent = t("err") + ": " + (err.data && err.data.error || err.message); }
  };
}

async function renderTariffs() {
  const { tariffs } = await api("/api/tariffs");
  app().innerHTML = `<h1>${t("tariffs")}</h1><section class="grid" id="g"></section><p class="err" id="e"></p>`;
  $("#g").innerHTML = tariffs.map((x) => `
    <article class="card glass">
      <h2>${esc(title(x))}</h2>
      <p class="price">${x.price_rub ? esc(x.price_rub) + " ₽" : t("trial")}<small> / ${esc(x.days)}d</small></p>
      <p class="muted">${x.traffic_gb ? esc(x.traffic_gb) + " GB" : "∞"} · ${x.devices || "∞"} devices</p>
      <p>${x.is_trial
        ? `<button class="btn ok" data-trial="${esc(x.id)}">${t("trial")}</button>`
        : `<button class="btn" data-buy="${esc(x.id)}">${t("buy")}</button>`}</p>
    </article>`).join("");
  app().onclick = async (ev) => {
    const trial = ev.target.getAttribute("data-trial");
    const buy = ev.target.getAttribute("data-buy");
    try {
      if (trial) {
        await api("/api/trial", { method: "POST", body: JSON.stringify({ tariff_id: Number(trial) }) });
        location.hash = "#/subscription";
      }
      if (buy) {
        const order = await api("/api/orders", { method: "POST", body: JSON.stringify({ tariff_id: Number(buy) }) });
        const paid = await api(`/api/orders/${order.order_id}/checkout`, { method: "POST", body: "{}" });
        if (paid.status === "pending") { $("#e").textContent = t("pending"); return; }
        location.hash = "#/subscription";
      }
    } catch (err) {
      $("#e").textContent = (err.status === 401) ? t("login") : (t("err") + ": " + (err.data && err.data.error || ""));
      if (err.status === 401) location.hash = "#/login";
    }
  };
}

async function renderSub() {
  let data = { has: false };
  try { data = await api("/api/subscription"); } catch (e) { if (e.status === 401) { location.hash = "#/login"; return; } }
  app().innerHTML = `
    <article class="card glass">
      <h1>${t("sub")}</h1>
      ${data.has ? `<p class="sub-url" id="url"></p><p><button class="btn" id="copy">${t("copy")}</button></p>`
                 : `<p class="muted">${t("none")}</p><p><a class="btn" href="#/tariffs">${t("tariffs")}</a></p>`}
    </article>`;
  const urlEl = $("#url");
  if (urlEl) urlEl.textContent = data.url || "";
  const b = $("#copy");
  if (b) b.onclick = () => { navigator.clipboard.writeText(data.url); b.textContent = t("copied"); };
}

async function renderHelp() {
  const { devices } = await api("/api/instructions");
  const keys = ["android", "ios", "tv", "pc"];
  app().innerHTML = `<h1>${t("help")}</h1><div class="tabs">${keys.map((k) => `<button class="chip" data-d="${k}">${t(k)}</button>`).join("")}</div><article class="card glass"><pre id="txt" style="white-space:pre-wrap;font:inherit"></pre></article>`;
  const show = (k) => { $("#txt").textContent = (devices[k] && (devices[k][S.lang] || devices[k].ru)) || ""; };
  show("android");
  app().onclick = (ev) => { const d = ev.target.getAttribute("data-d"); if (d) show(d); };
}

async function renderPage(slug) {
  const page = await api("/api/pages/" + encodeURIComponent(slug));
  app().innerHTML = `<article class="card glass"><h1></h1><div id="body"></div></article>`;
  app().querySelector("h1").textContent = title(page);
  $("#body").innerHTML = page.body || "";
}

async function boot() {
  S.cfg = await api("/api/public/config");
  try { S.me = (await api("/api/me")).user; } catch (_) { S.me = null; }
  nav();
  $("#langBtn").onclick = () => { S.lang = S.lang === "ru" ? "en" : "ru"; localStorage.setItem("lk_lang", S.lang); nav(); route(); };
  $("#authBtn").onclick = async () => {
    if (S.me) { await api("/api/auth/logout", { method: "POST", body: "{}" }); S.me = null; nav(); location.hash = "#/"; }
    else location.hash = "#/login";
  };
  window.addEventListener("hashchange", () => { route(); });
  window.addEventListener("pageshow", () => { route(); });
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") route();
  });
  route();
}
boot();
