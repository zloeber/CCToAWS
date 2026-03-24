const cfg = window.CCT_DASHBOARD_CONFIG;

function b64url(buf) {
  const bin = String.fromCharCode(...new Uint8Array(buf));
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function pkcePair() {
  const verifierArr = new Uint8Array(32);
  crypto.getRandomValues(verifierArr);
  const verifier = b64url(verifierArr);
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier));
  const challenge = b64url(digest);
  return { verifier, challenge };
}

function parseJwtPayload(token) {
  try {
    const part = token.split(".")[1];
    const json = atob(part.replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(json);
  } catch {
    return {};
  }
}

function setErr(msg) {
  const el = document.getElementById("err");
  if (!msg) {
    el.hidden = true;
    el.textContent = "";
    return;
  }
  el.hidden = false;
  el.textContent = msg;
}

async function apiFetch(path, opts = {}) {
  const token = sessionStorage.getItem("access_token");
  const headers = { ...(opts.headers || {}) };
  if (token) {
    headers.Authorization = "Bearer " + token;
  }
  const res = await fetch(cfg.apiBaseUrl.replace(/\/$/, "") + path, {
    ...opts,
    headers,
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }
  if (!res.ok) {
    const msg = data.error || data.message || res.statusText || "request failed";
    throw new Error(typeof msg === "string" ? msg : JSON.stringify(data));
  }
  return data;
}

function renderApps(apps) {
  const tbody = document.getElementById("apps-body");
  const table = document.getElementById("apps-table");
  const empty = document.getElementById("apps-empty");
  tbody.replaceChildren();
  if (!apps.length) {
    table.hidden = true;
    empty.hidden = false;
    return;
  }
  empty.hidden = true;
  table.hidden = false;
  for (const a of apps) {
    const tr = document.createElement("tr");
    const url =
      a.deployment_type === "static"
        ? a.static_url || "—"
        : a.runtime_url || a.image_uri || "—";
    tr.innerHTML = `
      <td><code>${escapeHtml(a.app_id)}</code></td>
      <td>${escapeHtml(a.deployment_type || "—")}</td>
      <td><code>${escapeHtml(a.revision || "—")}</code></td>
      <td><code>${escapeHtml(String(url))}</code></td>
      <td><button type="button" class="danger" data-app="${escapeHtml(a.app_id)}">Remove</button></td>
    `;
    tbody.appendChild(tr);
  }
  tbody.querySelectorAll("button[data-app]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const id = btn.getAttribute("data-app");
      if (!confirm(`Remove registry entry for "${id}"? This does not delete S3 or ECR data.`)) {
        return;
      }
      setErr("");
      try {
        await apiFetch("/v1/dashboard/apps/" + encodeURIComponent(id), { method: "DELETE" });
        await loadApps();
      } catch (e) {
        setErr(String(e.message || e));
      }
    });
  });
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function loadApps() {
  setErr("");
  const data = await apiFetch("/v1/dashboard/apps");
  renderApps(data.apps || []);
}

function updateAuthUi() {
  const token = sessionStorage.getItem("access_token");
  const login = document.getElementById("btn-login");
  const logout = document.getElementById("btn-logout");
  const label = document.getElementById("user-label");
  if (token) {
    login.hidden = true;
    logout.hidden = false;
    const p = parseJwtPayload(token);
    label.textContent = p.email || p["cognito:username"] || p.sub || "";
  } else {
    login.hidden = false;
    logout.hidden = true;
    label.textContent = "";
  }
}

async function main() {
  if (!cfg) {
    setErr("config.js missing — run terraform apply to publish dashboard assets.");
    return;
  }

  document.getElementById("btn-logout").addEventListener("click", () => {
    sessionStorage.removeItem("access_token");
    sessionStorage.removeItem("refresh_token");
    updateAuthUi();
    renderApps([]);
    document.getElementById("apps-empty").hidden = false;
    document.getElementById("apps-table").hidden = true;
  });

  document.getElementById("btn-login").addEventListener("click", async () => {
    setErr("");
    const { verifier, challenge } = await pkcePair();
    sessionStorage.setItem("pkce_verifier", verifier);
    const q = new URLSearchParams({
      client_id: cfg.clientId,
      response_type: "code",
      scope: "openid email profile",
      redirect_uri: cfg.redirectUri,
      code_challenge_method: "S256",
      code_challenge: challenge,
    });
    window.location.href =
      "https://" + cfg.hostedUiDomain + "/oauth2/authorize?" + q.toString();
  });

  updateAuthUi();
  if (!sessionStorage.getItem("access_token")) {
    document.getElementById("apps-empty").hidden = false;
    document.getElementById("apps-table").hidden = true;
    return;
  }
  try {
    await loadApps();
  } catch (e) {
    setErr(String(e.message || e));
  }
}

main();
