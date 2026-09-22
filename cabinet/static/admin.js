const $ = (s) => document.querySelector(s);
const BASE = document.body.getAttribute("data-prefix") || "";
const app = () => $("#app");
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
  app().innerHTML = `<article class="card" style="max-width:420px;margin:48px auto">
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
    app().innerHTML = `<p class="err">${e.message}</p>`;
  }
}

async function renderMenu() {
  const { items } = await api("/api/admin/menu");
  app().innerHTML = `<h1>Меню кабинета</h1>
    <p class="muted">Вкладки личного кабинета. kind: home, tariffs, subscription, instructions или page (произвольный текст).</p>
    <div id="list" class="grid"></div>
    <article class="card"><h2>Новая вкладка</h2>
      <form id="f">
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
  $("#list").innerHTML = items.map((m) => `<article class="card">
    <h2>${m.title_ru}</h2><p class="muted">${m.kind} · ${m.slug} · sort ${m.sort}</p>
    ${m.kind === "page" ? `<button class="btn warn" data-del="${m.id}">Удалить</button>` : ""}
  </article>`).join("");
  $("#f").onsubmit = async (ev) => {
    ev.preventDefault();
    const body = Object.fromEntries(new FormData(ev.target));
    body.sort = Number(body.sort || 50); body.enabled = 1;
    try { await api("/api/admin/menu", { method: "POST", body: JSON.stringify(body) }); render(); }
    catch (e) { $("#e").textContent = e.data && e.data.error || e.message; }
  };
  app().onclick = async (ev) => {
    const id = ev.target.getAttribute("data-del");
    if (!id) return;
    await api("/api/admin/menu/" + id, { method: "DELETE" });
    render();
  };
}

async function renderTariffs() {
  const { tariffs } = await api("/api/admin/tariffs");
  app().innerHTML = `<h1>Тарифы</h1><div class="grid" id="g"></div>
    <article class="card"><h2>Новый тариф</h2>
      <form id="f">
        <label>slug</label><input name="slug" required>
        <label>Название RU</label><input name="title_ru" required>
        <label>Title EN</label><input name="title_en" required>
        <label>Дни</label><input name="days" type="number" value="30">
        <label>Трафик GB (0 = ∞)</label><input name="traffic_gb" type="number" value="100">
        <label>Устройства (0 = без лимита)</label><input name="devices" type="number" value="2">
        <label>Цена ₽</label><input name="price_rub" type="number" value="199">
        <label><input name="is_trial" type="checkbox" value="1"> пробный</label>
        <button class="btn" type="submit">Сохранить</button>
      </form></article>`;
  $("#g").innerHTML = tariffs.map((x) => `<article class="card"><h2>${x.title_ru}</h2>
    <p>${x.days}d · ${x.price_rub}₽ · ${x.is_trial ? "trial" : ""}</p>
    <button class="btn warn" data-del="${x.id}">Удалить</button></article>`).join("");
  $("#f").onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const body = Object.fromEntries(fd);
    body.is_trial = fd.get("is_trial") ? 1 : 0;
    ["days", "traffic_gb", "devices", "price_rub"].forEach((k) => body[k] = Number(body[k] || 0));
    await api("/api/admin/tariffs", { method: "POST", body: JSON.stringify(body) });
    render();
  };
  app().onclick = async (ev) => {
    const id = ev.target.getAttribute("data-del");
    if (id) { await api("/api/admin/tariffs/" + id, { method: "DELETE" }); render(); }
  };
}

async function renderOrders() {
  const { orders } = await api("/api/admin/orders");
  app().innerHTML = `<h1>Заказы</h1><table class="table"><thead><tr><th>id</th><th>email</th><th>тариф</th><th>₽</th><th>статус</th><th></th></tr></thead>
    <tbody>${orders.map((o) => `<tr><td>${o.id}</td><td>${o.email || ""}</td><td>${o.title_ru}</td><td>${o.amount}</td><td>${o.status}</td>
      <td>${o.status !== "paid" ? `<button class="btn" data-paid="${o.id}">Отметить оплаченным</button>` : ""}</td></tr>`).join("")}</tbody></table>`;
  app().onclick = async (ev) => {
    const id = ev.target.getAttribute("data-paid");
    if (id) { await api("/api/admin/orders/" + id + "/paid", { method: "POST", body: "{}" }); render(); }
  };
}

async function renderUsers() {
  const { users } = await api("/api/admin/users");
  app().innerHTML = `<h1>Пользователи</h1><table class="table"><thead><tr><th>id</th><th>email</th><th>tg</th><th>vk</th><th>ya</th><th>sub</th></tr></thead>
    <tbody>${users.map((u) => `<tr><td>${u.id}</td><td>${u.email || ""}</td><td>${u.telegram_id ? "yes" : ""}</td>
      <td>${u.vk_id ? "yes" : ""}</td><td>${u.yandex_id ? "yes" : ""}</td><td>${u.short_uuid || ""}</td></tr>`).join("")}</tbody></table>`;
}

async function renderSettings() {
  const s = await api("/api/admin/settings");
  app().innerHTML = `<h1>Настройки</h1><article class="card"><form id="f">
    <label>Бренд</label><input name="brand" value="${s.brand || ""}">
    <label>Слоган RU</label><input name="tagline_ru" value="${s.tagline_ru || ""}">
    <label>Tagline EN</label><input name="tagline_en" value="${s.tagline_en || ""}">
    <label>Оплата</label><select name="payment_mode"><option value="mock"${s.payment_mode === "mock" ? " selected" : ""}>mock (без шлюзов)</option>
      <option value="manual"${s.payment_mode === "manual" ? " selected" : ""}>ручное подтверждение</option></select>
    <label>Пробный период</label><select name="trial_enabled"><option value="1">вкл</option><option value="0"${s.trial_enabled === "0" ? " selected" : ""}>выкл</option></select>
    <label>Публичный URL кабинета</label><input name="public_url" value="${s.public_url || ""}">
    <h2>OAuth</h2>
    <label>Telegram bot username</label><input name="tg_bot_name" value="${s.tg_bot_name || ""}">
    <label>Telegram bot token</label><input name="tg_bot_token" type="password" placeholder="${s.has_tg_bot_token ? "задан" : ""}">
    <label>VK client id</label><input name="vk_client_id" value="${s.vk_client_id || ""}">
    <label>VK secret</label><input name="vk_client_secret" type="password" placeholder="${s.has_vk_secret ? "задан" : ""}">
    <label>Yandex client id</label><input name="ya_client_id" value="${s.ya_client_id || ""}">
    <label>Yandex secret</label><input name="ya_client_secret" type="password" placeholder="${s.has_ya_secret ? "задан" : ""}">
    <label>Включить Telegram / VK / Yandex</label>
    <p><label><input type="checkbox" name="oauth_telegram" ${s.oauth_telegram === "1" ? "checked" : ""}> Telegram</label>
       <label><input type="checkbox" name="oauth_vk" ${s.oauth_vk === "1" ? "checked" : ""}> VK</label>
       <label><input type="checkbox" name="oauth_yandex" ${s.oauth_yandex === "1" ? "checked" : ""}> Yandex</label></p>
    <label>Новый пароль администратора</label><input name="admin_password" type="password" minlength="8">
    <p class="ok" id="ok"></p>
    <button class="btn" type="submit">Сохранить</button>
  </form></article>`;
  $("#f").onsubmit = async (ev) => {
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
  app().innerHTML = `<h1>Инструкции устройств</h1><article class="card"><form id="f"></form></article>`;
  const f = $("#f");
  ["android", "ios", "tv", "pc"].forEach((d) => {
    f.innerHTML += `<h2>${d}</h2><label>RU</label><textarea name="${d}_ru" rows="4">${(devices[d] && devices[d].ru) || ""}</textarea>
      <label>EN</label><textarea name="${d}_en" rows="4">${(devices[d] && devices[d].en) || ""}</textarea>`;
  });
  f.innerHTML += `<p><button class="btn" type="submit">Сохранить</button></p>`;
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
