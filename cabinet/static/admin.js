const $ = (s) => document.querySelector(s);
const BASE = document.body.getAttribute("data-prefix") || "";
const app = () => $("#app");
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
}[c]));
let tab = "menu";

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

function loginView() {
  app().innerHTML = `<article class="card glass" style="max-width:420px;margin:48px auto">
    <h1>Кабинет администратора</h1>
    <p class="muted">Пароль задаётся в настройках установщика. В тесте: <code>corgi-test</code>.</p>
    <form id="f"><label>Пароль</label><input name="password" type="password" required><p class="err" id="e"></p>
    <button class="btn" type="submit">Войти</button></form></article>`;
  $("#f").onsubmit = async (ev) => {
    ev.preventDefault();
    const password = new FormData(ev.target).get("password");
    try { await api("/api/admin/login", { method: "POST", body: JSON.stringify({ password }) }); boot(); }
    catch (e) { $("#e").textContent = "Неверный пароль"; }
  };
}

function tabs() {
  $("#tabs").innerHTML = ["menu", "tariffs", "orders", "users", "settings", "help"].map((x) =>
    `<a href="#" data-t="${x}" class="${x === tab ? "active" : ""}">${x}</a>`).join("");
  $("#tabs").onclick = (ev) => {
    ev.preventDefault();
    const t = ev.target.getAttribute("data-t");
    if (t) { tab = t; render(); }
  };
}

async function render() {
  tabs();
  try {
    if (tab === "menu") return renderMenu();
    if (tab === "tariffs") return renderTariffs();
    if (tab === "orders") return renderOrders();
    if (tab === "users") return renderUsers();
    if (tab === "help") return renderHelp();
    return renderSettings();
  } catch (e) {
    if (e.status === 401) return loginView();
    app().innerHTML = `<p class="err">${esc(e.message)}</p>`;
  }
}

function fillForm(form, data) {
  Object.entries(data).forEach(([k, v]) => {
    const el = form.elements[k];
    if (!el) return;
    if (el.type === "checkbox") el.checked = Boolean(Number(v));
    else el.value = v == null ? "" : String(v);
  });
}

async function renderMenu() {
  const { items } = await api("/api/admin/menu");
  app().innerHTML = `<h1>Меню кабинета</h1>
    <p class="muted">Вкладки личного кабинета. kind: home, tariffs, subscription, instructions или page (произвольный HTML).</p>
    <div id="list" class="grid"></div>
    <article class="card glass"><h2 id="formTitle">Новая вкладка</h2>
      <form id="f">
        <input type="hidden" name="id" value="">
        <label>slug</label><input name="slug" required placeholder="faq">
        <label>Название RU</label><input name="title_ru" required>
        <label>Title EN</label><input name="title_en" required>
        <label>kind</label><select name="kind"><option>page</option><option>home</option><option>tariffs</option><option>subscription</option><option>instructions</option></select>
        <label>icon</label><input name="icon" placeholder="info">
        <label>sort</label><input name="sort" type="number" value="50">
        <label>HTML вкладки</label><textarea name="body" rows="5"></textarea>
        <p class="err" id="e"></p>
        <button class="btn" type="submit">Сохранить вкладку</button>
      </form>
    </article>`;
  $("#list").innerHTML = items.map((m) => `<article class="card glass">
    <h2>${esc(m.title_ru)}</h2><p class="muted">${esc(m.kind)} · ${esc(m.slug)} · sort ${esc(m.sort)}</p>
    <p><button class="btn ghost" data-edit="${esc(m.id)}">Изменить</button>
    ${m.kind === "page" ? `<button class="btn warn" data-del="${esc(m.id)}">Удалить</button>` : ""}</p>
  </article>`).join("");
  const form = $("#f");
  form.onsubmit = async (ev) => {
    ev.preventDefault();
    const body = Object.fromEntries(new FormData(ev.target));
    body.sort = Number(body.sort || 50); body.enabled = 1;
    if (!body.id) delete body.id; else body.id = Number(body.id);
    try { await api("/api/admin/menu", { method: "POST", body: JSON.stringify(body) }); render(); }
    catch (e) { $("#e").textContent = e.data && e.data.error || e.message; }
  };
  app().onclick = async (ev) => {
    const del = ev.target.getAttribute("data-del");
    const edit = ev.target.getAttribute("data-edit");
    if (del) {
      await api("/api/admin/menu/" + del, { method: "DELETE" });
      render();
      return;
    }
    if (edit) {
      const item = items.find((x) => String(x.id) === String(edit));
      if (!item) return;
      $("#formTitle").textContent = "Изменить вкладку";
      fillForm(form, item);
    }
  };
}

async function renderTariffs() {
  const { tariffs } = await api("/api/admin/tariffs");
  app().innerHTML = `<h1>Тарифы</h1><div class="grid" id="g"></div>
    <article class="card glass"><h2 id="formTitle">Новый тариф</h2>
      <form id="f">
        <input type="hidden" name="id" value="">
        <label>slug</label><input name="slug" required>
        <label>Название RU</label><input name="title_ru" required>
        <label>Title EN</label><input name="title_en" required>
        <label>Дни</label><input name="days" type="number" value="30">
        <label>Трафик GB (0 = ∞)</label><input name="traffic_gb" type="number" value="100">
        <label>Устройства (0 = без лимита)</label><input name="devices" type="number" value="2">
        <label>Цена ₽</label><input name="price_rub" type="number" value="199">
        <label>sort</label><input name="sort" type="number" value="50">
        <label><input name="is_trial" type="checkbox" value="1"> пробный</label>
        <button class="btn" type="submit">Сохранить</button>
      </form></article>`;
  $("#g").innerHTML = tariffs.map((x) => `<article class="card glass"><h2>${esc(x.title_ru)}</h2>
    <p>${esc(x.days)}d · ${esc(x.price_rub)}₽ · ${x.is_trial ? "trial" : ""} ${x.enabled ? "" : "· выкл"}</p>
    <p><button class="btn ghost" data-edit="${esc(x.id)}">Изменить</button>
       <button class="btn warn" data-del="${esc(x.id)}">Удалить</button></p></article>`).join("");
  const form = $("#f");
  form.onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const body = Object.fromEntries(fd);
    body.is_trial = fd.get("is_trial") ? 1 : 0;
    ["days", "traffic_gb", "devices", "price_rub", "sort"].forEach((k) => body[k] = Number(body[k] || 0));
    if (!body.id) delete body.id; else body.id = Number(body.id);
    await api("/api/admin/tariffs", { method: "POST", body: JSON.stringify(body) });
    render();
  };
  app().onclick = async (ev) => {
    const id = ev.target.getAttribute("data-del");
    const edit = ev.target.getAttribute("data-edit");
    if (id) { await api("/api/admin/tariffs/" + id, { method: "DELETE" }); render(); }
    if (edit) {
      const item = tariffs.find((x) => String(x.id) === String(edit));
      if (!item) return;
      $("#formTitle").textContent = "Изменить тариф";
      fillForm(form, item);
    }
  };
}

async function renderOrders() {
  const { orders } = await api("/api/admin/orders");
  app().innerHTML = `<h1>Заказы</h1><table class="table"><thead><tr><th>id</th><th>email</th><th>тариф</th><th>₽</th><th>статус</th><th></th></tr></thead>
    <tbody>${orders.map((o) => `<tr><td>${esc(o.id)}</td><td>${esc(o.email || "")}</td><td>${esc(o.title_ru)}</td><td>${esc(o.amount)}</td><td>${esc(o.status)}</td>
      <td>${o.status !== "paid" ? `<button class="btn" data-paid="${esc(o.id)}">Отметить оплаченным</button>` : ""}</td></tr>`).join("")}</tbody></table>`;
  app().onclick = async (ev) => {
    const id = ev.target.getAttribute("data-paid");
    if (id) { await api("/api/admin/orders/" + id + "/paid", { method: "POST", body: "{}" }); render(); }
  };
}

async function renderUsers() {
  const { users } = await api("/api/admin/users");
  app().innerHTML = `<h1>Пользователи</h1><table class="table"><thead><tr><th>id</th><th>email</th><th>tg</th><th>vk</th><th>ya</th><th>sub</th></tr></thead>
    <tbody>${users.map((u) => `<tr><td>${esc(u.id)}</td><td>${esc(u.email || "")}</td><td>${u.telegram_id ? "yes" : ""}</td>
      <td>${u.vk_id ? "yes" : ""}</td><td>${u.yandex_id ? "yes" : ""}</td><td>${esc(u.short_uuid || "")}</td></tr>`).join("")}</tbody></table>`;
}

async function renderSettings() {
  const s = await api("/api/admin/settings");
  app().innerHTML = `<h1>Настройки</h1><article class="card glass"><form id="f">
    <label>Бренд</label><input name="brand">
    <label>Слоган RU</label><input name="tagline_ru">
    <label>Tagline EN</label><input name="tagline_en">
    <label>Оплата</label><select name="payment_mode">
      <option value="mock">mock (без шлюзов)</option>
      <option value="manual">ручное подтверждение</option></select>
    <label>Пробный период</label><select name="trial_enabled"><option value="1">вкл</option><option value="0">выкл</option></select>
    <label>Публичный URL кабинета</label><input name="public_url">
    <h2>OAuth</h2>
    <label>Telegram bot username</label><input name="tg_bot_name">
    <label>Telegram bot token</label><input name="tg_bot_token" type="password">
    <label>VK client id</label><input name="vk_client_id">
    <label>VK secret</label><input name="vk_client_secret" type="password">
    <label>Yandex client id</label><input name="ya_client_id">
    <label>Yandex secret</label><input name="ya_client_secret" type="password">
    <label>Включить Telegram / VK / Yandex</label>
    <p><label><input type="checkbox" name="oauth_telegram"> Telegram</label>
       <label><input type="checkbox" name="oauth_vk"> VK</label>
       <label><input type="checkbox" name="oauth_yandex"> Yandex</label></p>
    <label>Новый пароль администратора</label><input name="admin_password" type="password" minlength="8">
    <p class="ok" id="ok"></p>
    <button class="btn" type="submit">Сохранить</button>
  </form></article>`;
  const form = $("#f");
  fillForm(form, s);
  form.elements.payment_mode.value = s.payment_mode || "mock";
  form.elements.trial_enabled.value = s.trial_enabled || "1";
  form.elements.oauth_telegram.checked = s.oauth_telegram === "1";
  form.elements.oauth_vk.checked = s.oauth_vk === "1";
  form.elements.oauth_yandex.checked = s.oauth_yandex === "1";
  if (s.has_tg_bot_token) form.elements.tg_bot_token.placeholder = "задан";
  if (s.has_vk_secret) form.elements.vk_client_secret.placeholder = "задан";
  if (s.has_ya_secret) form.elements.ya_client_secret.placeholder = "задан";
  form.onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const body = Object.fromEntries(fd);
    body.oauth_telegram = fd.get("oauth_telegram") ? "1" : "0";
    body.oauth_vk = fd.get("oauth_vk") ? "1" : "0";
    body.oauth_yandex = fd.get("oauth_yandex") ? "1" : "0";
    await api("/api/admin/settings", { method: "POST", body: JSON.stringify(body) });
    $("#ok").textContent = "Сохранено";
  };
}

async function renderHelp() {
  const { devices } = await api("/api/instructions");
  app().innerHTML = `<h1>Инструкции устройств</h1><article class="card glass"><form id="f"></form></article>`;
  const f = $("#f");
  ["android", "ios", "tv", "pc"].forEach((d) => {
    const wrap = document.createElement("div");
    wrap.innerHTML = `<h2>${d}</h2><label>RU</label><textarea name="${d}_ru" rows="4"></textarea>
      <label>EN</label><textarea name="${d}_en" rows="4"></textarea>`;
    wrap.querySelector(`[name="${d}_ru"]`).value = (devices[d] && devices[d].ru) || "";
    wrap.querySelector(`[name="${d}_en"]`).value = (devices[d] && devices[d].en) || "";
    f.appendChild(wrap);
  });
  const btn = document.createElement("p");
  btn.innerHTML = `<button class="btn" type="submit">Сохранить</button>`;
  f.appendChild(btn);
  f.onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = new FormData(f);
    const body = {};
    ["android", "ios", "tv", "pc"].forEach((d) => { body[d] = { ru: fd.get(d + "_ru"), en: fd.get(d + "_en") }; });
    await api("/api/admin/instructions", { method: "POST", body: JSON.stringify(body) });
    render();
  };
}

async function boot() {
  try {
    await api("/api/admin/me");
    $("#out").onclick = async () => { await api("/api/admin/logout", { method: "POST", body: "{}" }); loginView(); };
    render();
  } catch (_) { loginView(); }
}
boot();
