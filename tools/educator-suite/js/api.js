const API_BASE = "http://127.0.0.1:8000";
const ROJO_BASE = "http://localhost:34872";

function getToken() {
    return localStorage.getItem("saiydd_token");
}

function setToken(token) {
    if (token) {
        localStorage.setItem("saiydd_token", token);
    } else {
        localStorage.removeItem("saiydd_token");
    }
}

function getAuthHeaders() {
    const token = getToken();
    if (!token) return {};
    return { "Authorization": "Bearer " + token };
}

async function apiFetch(path, options = {}) {
    const headers = Object.assign({}, getAuthHeaders(), options.headers || {});
    const res = await fetch(API_BASE + path, Object.assign({}, options, { headers }));
    if (res.status === 401) {
        setToken(null);
        localStorage.removeItem("saiydd_user");
        setTimeout(() => {
            window.location.reload();
        }, 100);
        throw new Error("Sesión expirada");
    }
    return res;
}

async function login(email, password) {
    const res = await fetch(API_BASE + "/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim().toLowerCase(), password })
    });
    if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || "Credenciales inválidas");
    }
    const data = await res.json();
    setToken(data.access_token);
    return data;
}

function logout() {
    setToken(null);
}

async function getChild(childId) {
    const res = await apiFetch("/api/children/" + encodeURIComponent(childId));
    if (!res.ok) throw new Error("No se pudo obtener el niño");
    return res.json();
}

async function getProgress(childId) {
    const res = await apiFetch("/api/children/" + encodeURIComponent(childId) + "/progress");
    if (!res.ok) throw new Error("No se pudo obtener el progreso");
    return res.json();
}

async function getActivities() {
    const res = await apiFetch("/api/activities");
    if (!res.ok) throw new Error("No se pudieron obtener las actividades");
    return res.json();
}

async function getSessions(childId) {
    const res = await apiFetch("/api/children/" + encodeURIComponent(childId) + "/sessions");
    if (!res.ok) throw new Error("No se pudieron obtener las sesiones");
    return res.json();
}

async function getHealth() {
    try {
        const res = await fetch(API_BASE + "/api/health");
        if (!res.ok) throw new Error("Backend no disponible");
        return res.json();
    } catch (err) {
        throw err;
    }
}

async function getRojoTree() {
    try {
        const res = await fetch(ROJO_BASE + "/show-instances");
        if (!res.ok) throw new Error("Rojo no disponible");
        const text = await res.text();
        return { ok: true, raw: text };
    } catch (err) {
        return { ok: false, raw: "" };
    }
}

export { API_BASE, ROJO_BASE, getToken, setToken, getAuthHeaders, apiFetch, login, logout, getChild, getProgress, getActivities, getSessions, getHealth, getRojoTree };
