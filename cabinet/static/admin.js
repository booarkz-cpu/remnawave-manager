const $ = (s) => document.querySelector(s);
const BASE = document.body.getAttribute("data-prefix") || "";
const app = () => $("#app");
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
}[c]));
let tab = "menu";

const TABS = [
  { id: "menu", label: "Меню", icon: "M4 6h16v2H4zm0 5h16v2H4zm0 5h10v2H4z" },
  { id: "tariffs", label: "Тарифы", icon: "M12 2 2 7v2h20V7zm-8 9v8h4v-8zm6 0v8h4v-8zm6 0v8h4v-8z" },
  { id: "orders", label: "Заказы", icon: "M7 4h10l1 4H6zm-1 6h12v10H6z" },
  { id: "users", label: "Люди", icon: "M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4zm0 2c-4 0-8 2-8 5v1h16v-1c0-3-4-5-8-5z" },
  { id: "settings", label: "Настройки", icon: "M19.14 12.94a7.5 7.5 0 0 0 .06-1l2-1.55-2-3.46-2.4.6a7.4 7.4 0 0 0-1.7-1L14.5 4h-5l-.6 2.53a7.4 7.4 0 0 0-1.7 1l-2.4-.6-2 3.46 2 1.55a7.5 7.5 0 0 0 0 2L2.8 15.5l2 3.46 2.4-.6a7.4 7.4 0 0 0 1.7 1L9.5 22h5l.6-2.53a7.4 7.4 0 0 0 1.7-1l2.4.6 2-3.46zM12 15.5A3.5 3.5 0 1 1 15.5 12 3.5 3.5 0 0 1 12 15.5z" },
  { id: "help", label: "Гайды", icon: "M11 18h2v-2h-2zm1-16a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm1 15h-2v-6h2zm0-8h-2V7h2z" },
];

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

function lockChrome(on) {
  document.body.classList.toggle("admin-locked", on);
  const rail = $("#tabs");
  if (rail) rail.hidden = on;
}

function loginView() {
  lockChrome(true);
  app().innerHTML = `<article class="card glass login-card">
    <div class="mark"></div>
    <p class="eyebrow">Control plane</p>
    <h1>Кабинет администратора</h1>
    <p class="muted">Пароль задаётся установщиком. В тесте: <code>corgi-test</code>. Платежные шлюзы не подключаются.</p>
    <form id="f">
      <label>Пароль</label>
      <input name="password" type="password" required autocomplete="current-password">
      <p class="err" id="e"></p>
      <button class="btn" type="submit">Войти</button>
    </form>
  </article>`;
  $("#f").onsubmit = async (ev) => {
    ev.preventDefault();
    const password = new FormData(ev.target).get("password");
    try { await api("/api/admin/login", { method: "POST", body: JSON.stringify({ password }) }); boot(); }
    catch (e) { $("#e").textContent = "Неверный пароль"; }
  };
}

function tabs() {
  const n = $("#tabs");
  n.hidden = false;
  n.innerHTML = TABS.map((x) => `<a class="rail-item${x.id === tab ? " active" : ""}" href="#/${x.id}" data-t="${x.id}">
    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="${x.icon}"></path></svg>
    <span>${x.label}</span>
  </a>`).join("");
  n.onclick = (ev) => {
    const a = ev.target.closest("[data-t]");
    if (!a) return;
    ev.preventDefault();
    tab = a.getAttribute("data-t");
    render();
  };
}

function head(title, lead) {
  return `<header class="page-head"><div><p class="eyebrow">Админ</p><h1>${title}</h1><p class="muted">${lead}</p></div></header>`;
}

async function render() {
  lockChrome(false);
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
  app().innerHTML = `${head("Меню кабинета", "Вкладки, которые видит пользователь. kind: home, tariffs, subscription, instructions или page.")}
    <div id="list" class="grid"></div>
    <article class="card glass"><h2 id="formTitle">Новая вкладка</h2>
      <form id="f">
        <input type="hidden" name="id" value="">
        <div class="form-grid">
          <div><label>slug (латиница)</label>
            <input name="slug" required pattern="[a-z0-9][a-z0-9-]{0,47}" maxlength="48"
                   autocomplete="off" autocapitalize="off" spellcheck="false"
                   title="Только a-z, 0-9 и дефис, например faq">
            <p class="muted">Не название вкладки. Пример: <code>faq</code></p>
          </div>
          <div><label>sort</label><input name="sort" type="number" value="50"></div>
          <div><label>Название RU</label><input name="title_ru" required placeholder="Вопросы"></div>
          <div><label>Title EN</label><input name="title_en" required placeholder="FAQ"></div>
          <div><label>kind</label><select name="kind"><option>page</option><option>home</option><option>tariffs</option><option>subscription</option><option>instructions</option></select></div>
          <div><label>icon</label><input name="icon"></div>
          <div class="span-2"><label>HTML вкладки</label><textarea name="body" rows="5"></textarea></div>
        </div>
        <label class="switch"><input name="enabled" type="checkbox" checked> показывать во вкладках</label>
        <p class="err" id="e"></p>
        <div class="row-actions">
          <button class="btn" type="submit">Сохранить вкладку</button>
          <button class="btn ghost" type="button" id="resetMenu">Новая вкладка</button>
        </div>
      </form>
    </article>`;
  $("#list").innerHTML = items.length ? items.map((m) => `<article class="card glass">
    <p><span class="badge">${esc(m.kind)}</span> ${m.enabled ? '<span class="badge ok">on</span>' : '<span class="badge warn">off</span>'}</p>
    <h2>${esc(m.title_ru)}</h2>
    <p class="muted">${esc(m.slug)} · sort ${esc(m.sort)}</p>
    <div class="row-actions">
      <button class="btn tonal" data-edit="${esc(m.id)}">Изменить</button>
      ${m.kind === "page" ? `<button class="btn warn" data-del="${esc(m.id)}">Удалить</button>` : ""}
    </div>
  </article>`).join("") : `<div class="empty card glass"><strong>Вкладок нет</strong>Добавьте первую ниже.</div>`;
  const form = $("#f");
  const slugInput = form.elements.slug;
  slugInput.addEventListener("input", () => {
    const next = String(slugInput.value || "").toLowerCase().replace(/[^a-z0-9-]/g, "");
    if (slugInput.value !== next) slugInput.value = next;
  });
  const resetMenu = () => {
    form.reset();
    form.elements.id.value = "";
    form.elements.enabled.checked = true;
    $("#formTitle").textContent = "Новая вкладка";
    slugInput.focus();
  };
  $("#resetMenu").onclick = resetMenu;
  form.onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const body = Object.fromEntries(fd);
    body.slug = String(body.slug || "").toLowerCase().trim();
    body.sort = Number(body.sort || 50);
    body.enabled = fd.get("enabled") ? 1 : 0;
    if (!body.id) delete body.id; else body.id = Number(body.id);
    try { await api("/api/admin/menu", { method: "POST", body: JSON.stringify(body) }); render(); }
    catch (e) { $("#e").textContent = e.data && e.data.error || e.message; }
  };
  const list = $("#list");
  list.onclick = async (ev) => {
    const del = ev.target.getAttribute("data-del");
    const edit = ev.target.getAttribute("data-edit");
    if (del) { await api("/api/admin/menu/" + del, { method: "DELETE" }); render(); return; }
    if (edit) {
      const item = items.find((x) => String(x.id) === String(edit));
      if (!item) return;
      $("#formTitle").textContent = "Изменить вкладку · " + item.slug;
      fillForm(form, item);
      form.elements.enabled.checked = Boolean(Number(item.enabled));
      form.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };
}

async function renderTariffs() {
  const { tariffs } = await api("/api/admin/tariffs");
  app().innerHTML = `${head("Тарифы", "Пробный период и платные планы. Без SDK платёжных шлюзов.")}
    <div class="grid" id="g"></div>
    <article class="card glass"><h2 id="formTitle">Новый тариф</h2>
      <form id="f">
        <input type="hidden" name="id" value="">
        <div class="form-grid">
          <div><label>slug</label><input name="slug" required></div>
          <div><label>sort</label><input name="sort" type="number" value="50"></div>
          <div><label>Название RU</label><input name="title_ru" required></div>
          <div><label>Title EN</label><input name="title_en" required></div>
          <div><label>Дни</label><input name="days" type="number" value="30"></div>
          <div><label>Трафик GB (0 = ∞)</label><input name="traffic_gb" type="number" value="100"></div>
          <div><label>Устройства (0 = без лимита)</label><input name="devices" type="number" value="2"></div>
          <div><label>Цена ₽</label><input name="price_rub" type="number" value="199"></div>
        </div>
        <label class="switch"><input name="is_trial" type="checkbox" value="1"> пробный период</label>
        <label class="switch"><input name="enabled" type="checkbox" checked> показывать пользователям</label>
        <button class="btn" type="submit">Сохранить</button>
      </form></article>`;
  $("#g").innerHTML = tariffs.length ? tariffs.map((x) => `<article class="card glass">
    <p>${x.is_trial ? '<span class="badge ok">trial</span>' : '<span class="badge">plan</span>'}
       ${x.enabled ? "" : '<span class="badge warn">выкл</span>'}</p>
    <h2>${esc(x.title_ru)}</h2>
    <p class="price">${esc(x.price_rub)} ₽<small> / ${esc(x.days)}d</small></p>
    <p class="muted">${x.traffic_gb ? esc(x.traffic_gb) + " GB" : "∞"} · ${x.devices || "∞"} devices</p>
    <div class="row-actions">
      <button class="btn tonal" data-edit="${esc(x.id)}">Изменить</button>
      <button class="btn warn" data-del="${esc(x.id)}">Удалить</button>
    </div>
  </article>`).join("") : `<div class="empty card glass"><strong>Тарифов нет</strong></div>`;
  const form = $("#f");
  form.onsubmit = async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const body = Object.fromEntries(fd);
    body.is_trial = fd.get("is_trial") ? 1 : 0;
    body.enabled = fd.get("enabled") ? 1 : 0;
    ["days", "traffic_gb", "devices", "price_rub", "sort"].forEach((k) => body[k] = Number(body[k] || 0));
    if (!body.id) delete body.id; else body.id = Number(body.id);
    await api("/api/admin/tariffs", { method: "POST", body: JSON.stringify(body) });
    render();
  };
  const list = $("#g");
  list.onclick = async (ev) => {
    const id = ev.target.getAttribute("data-del");
    const edit = ev.target.getAttribute("data-edit");
    if (id) { await api("/api/admin/tariffs/" + id, { method: "DELETE" }); render(); return; }
    if (edit) {
      const item = tariffs.find((x) => String(x.id) === String(edit));
      if (!item) return;
      $("#formTitle").textContent = "Изменить тариф";
      fillForm(form, item);
      form.elements.is_trial.checked = Boolean(Number(item.is_trial));
      form.elements.enabled.checked = Boolean(Number(item.enabled));
      form.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };
}

async function renderOrders() {
  const { orders } = await api("/api/admin/orders");
  const pending = orders.filter((o) => o.status !== "paid").length;
  app().innerHTML = `${head("Заказы", "Mock-оплата или ручное подтверждение. Шлюзы не устанавливаются.")}
    <section class="stats">
      <article class="card glass stat"><span class="muted">Всего</span><b>${orders.length}</b></article>
      <article class="card glass stat"><span class="muted">Ожидают</span><b>${pending}</b></article>
      <article class="card glass stat"><span class="muted">Оплачены</span><b>${orders.length - pending}</b></article>
    </section>
    ${orders.length ? `<div class="table-wrap"><table class="table"><thead><tr><th>id</th><th>email</th><th>тариф</th><th>₽</th><th>статус</th><th></th></tr></thead>
    <tbody>${orders.map((o) => `<tr><td>${esc(o.id)}</td><td>${esc(o.email || "")}</td><td>${esc(o.title_ru)}</td><td>${esc(o.amount)}</td>
      <td>${o.status === "paid" ? '<span class="badge ok">paid</span>' : '<span class="badge warn">pending</span>'}</td>
      <td>${o.status !== "paid" ? `<button class="btn" data-paid="${esc(o.id)}">Отметить оплаченным</button>` : ""}</td></tr>`).join("")}</tbody></table></div>`
      : `<div class="empty card glass"><strong>Заказов пока нет</strong>Пользователь ещё не брал тариф.</div>`}`;
  app().onclick = async (ev) => {
    const id = ev.target.getAttribute("data-paid");
    if (id) { await api("/api/admin/orders/" + id + "/paid", { method: "POST", body: "{}" }); render(); }
  };
}

async function renderUsers() {
  const { users } = await api("/api/admin/users");
  const withSub = users.filter((u) => u.short_uuid).length;
  app().innerHTML = `${head("Пользователи", "Email, Telegram, VK, Яндекс. Ссылка подписки — shortUuid.")}
    <section class="stats">
      <article class="card glass stat"><span class="muted">Аккаунты</span><b>${users.length}</b></article>
      <article class="card glass stat"><span class="muted">С подпиской</span><b>${withSub}</b></article>
    </section>
    ${users.length ? `<div class="table-wrap"><table class="table"><thead><tr><th>id</th><th>email</th><th>tg</th><th>vk</th><th>ya</th><th>sub</th></tr></thead>
    <tbody>${users.map((u) => `<tr><td>${esc(u.id)}</td><td>${esc(u.email || "")}</td><td>${u.telegram_id ? "yes" : "—"}</td>
      <td>${u.vk_id ? "yes" : "—"}</td><td>${u.yandex_id ? "yes" : "—"}</td><td>${esc(u.short_uuid || "—")}</td></tr>`).join("")}</tbody></table></div>`
      : `<div class="empty card glass"><strong>Пользователей нет</strong></div>`}`;
}

async function renderSettings() {
  const s = await api("/api/admin/settings");
  app().innerHTML = `${head("Настройки", "Бренд, оплата, OAuth. Секреты в форме не возвращаются.")}
    <article class="card glass"><form id="f">
    <div class="form-grid">
      <div><label>Бренд</label><input name="brand"></div>
      <div><label>Публичный URL</label><input name="public_url"></div>
      <div class="span-2"><label>Слоган RU</label><input name="tagline_ru"></div>
      <div class="span-2"><label>Tagline EN</label><input name="tagline_en"></div>
      <div><label>Оплата</label><select name="payment_mode">
        <option value="mock">mock (без шлюзов)</option>
        <option value="manual">ручное подтверждение</option></select></div>
      <div><label>Пробный период</label><select name="trial_enabled"><option value="1">вкл</option><option value="0">выкл</option></select></div>
    </div>
    <h2>OAuth</h2>
    <div class="form-grid">
      <div><label>Telegram bot username</label><input name="tg_bot_name"></div>
      <div><label>Telegram bot token</label><input name="tg_bot_token" type="password"></div>
      <div><label>VK client id</label><input name="vk_client_id"></div>
      <div><label>VK secret</label><input name="vk_client_secret" type="password"></div>
      <div><label>Yandex client id</label><input name="ya_client_id"></div>
      <div><label>Yandex secret</label><input name="ya_client_secret" type="password"></div>
    </div>
    <label class="switch"><input type="checkbox" name="oauth_telegram"> Telegram</label>
    <label class="switch"><input type="checkbox" name="oauth_vk"> VK</label>
    <label class="switch"><input type="checkbox" name="oauth_yandex"> Yandex</label>
    <label>Новый пароль администратора</label><input name="admin_password" type="password" minlength="8" autocomplete="new-password">
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
  app().innerHTML = `${head("Инструкции устройств", "Тексты для Android, iOS, ТВ и компьютера — как видит пользователь.")}
    <article class="card glass"><form id="f" class="help-grid"></form></article>`;
  const f = $("#f");
  ["android", "ios", "tv", "pc"].forEach((d) => {
    const wrap = document.createElement("div");
    wrap.className = "card glass";
    wrap.innerHTML = `<h2>${d}</h2><label>RU</label><textarea name="${d}_ru" rows="6"></textarea>
      <label>EN</label><textarea name="${d}_en" rows="6"></textarea>`;
    wrap.querySelector(`[name="${d}_ru"]`).value = (devices[d] && devices[d].ru) || "";
    wrap.querySelector(`[name="${d}_en"]`).value = (devices[d] && devices[d].en) || "";
    f.appendChild(wrap);
  });
  const btn = document.createElement("p");
  btn.className = "span-2";
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
  $("#out").onclick = async () => {
    try { await api("/api/admin/logout", { method: "POST", body: "{}" }); } catch (_) {}
    loginView();
  };
  try {
    await api("/api/admin/me");
    render();
  } catch (_) { loginView(); }
}
boot();
