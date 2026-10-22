import { getToken, setToken, login, logout, getChild, getProgress, getSessions, getActivities, getHealth, getRojoTree } from "./api.js";
import { formatDateTime, formatSeconds } from "./utils.js";

const loginView = document.getElementById("loginView");
const appView = document.getElementById("appView");
const loginForm = document.getElementById("loginForm");
const loginEmail = document.getElementById("loginEmail");
const loginPassword = document.getElementById("loginPassword");
const loginError = document.getElementById("loginError");
const logoutBtn = document.getElementById("logoutBtn");
const tutorInfo = document.getElementById("tutorInfo");

const navBtns = document.querySelectorAll(".nav-btn");
const tabSections = document.querySelectorAll(".tab-section");

const sessionModalEl = document.getElementById("sessionModal");
const modalCloseBtn = document.getElementById("modalClose");
const modalDate = document.getElementById("modalDate");
const modalActivity = document.getElementById("modalActivity");
const modalScore = document.getElementById("modalScore");
const modalDuration = document.getElementById("modalDuration");
const interactionList = document.getElementById("interactionList");

const cardTotalChildren = document.getElementById("cardTotalChildren");
const cardTotalSessions = document.getElementById("cardTotalSessions");
const cardAvgScore = document.getElementById("cardAvgScore");
const cardLastSession = document.getElementById("cardLastSession");
const dashboardRecentBody = document.getElementById("dashboardRecentBody");

const alumnosBody = document.getElementById("alumnosBody");

const fichaChildId = document.getElementById("fichaChildId");
const fichaChildName = document.getElementById("fichaChildName");
const fichaChildAvatar = document.getElementById("fichaChildAvatar");
const fichaChildCreated = document.getElementById("fichaChildCreated");
const fichaTotalSessions = document.getElementById("fichaTotalSessions");
const fichaAvgScore = document.getElementById("fichaAvgScore");
const fichaTotalTime = document.getElementById("fichaTotalTime");
const fichaLastActivity = document.getElementById("fichaLastActivity");
const evolutionChartCanvas = document.getElementById("evolutionChart");
let evolutionChart;

const historialBody = document.getElementById("historialBody");

const estadoBackend = document.getElementById("estadoBackend");
const estadoRojo = document.getElementById("estadoRojo");

const TEST_CHILD_ID = "child_TEST_001";
let activitiesMap = {};
let sessionsCache = [];

function showLogin() {
    if (!appView || !loginView) return;
    appView.style.display = "none";
    loginView.style.display = "block";
    if (loginError) loginError.style.display = "none";
    if (loginForm) loginForm.reset();
    if (tutorInfo) tutorInfo.textContent = "";
    localStorage.removeItem("saiydd_user");
}

function showApp(email) {
    if (!appView || !loginView) return;
    loginView.style.display = "none";
    appView.style.display = "block";
    if (tutorInfo) {
        tutorInfo.textContent = email ? email.trim().toLowerCase() : (localStorage.getItem("saiydd_user") || "");
    }
}

function setActiveTab(tabName) {
    navBtns.forEach(btn => {
        btn.classList.toggle("active", btn.dataset.tab === tabName);
    });
    tabSections.forEach(sec => {
        if (sec.id === "tab-" + tabName) {
            sec.style.display = "flex";
            sec.style.flexDirection = "column";
            sec.style.gap = "24px";
        } else {
            sec.style.display = "none";
        }
    });
    if (tabName === "dashboard" || tabName === "alumnos" || tabName === "ficha") {
        if (getToken()) {
            loadOverview();
        }
    }
    if (tabName === "historial") {
        if (getToken()) {
            loadHistorial();
        }
    }
    if (tabName === "ficha") {
        if (getToken()) {
            loadOverview();
        }
    }
    if (tabName === "estado") {
        if (getToken()) {
            loadSimulatorStatus();
        }
    }
}

navBtns.forEach(btn => {
    btn.addEventListener("click", () => {
        setActiveTab(btn.dataset.tab);
    });
});

if (modalCloseBtn && sessionModalEl) {
    modalCloseBtn.addEventListener("click", () => {
        sessionModalEl.classList.remove("active");
    });
}

if (sessionModalEl) {
    sessionModalEl.addEventListener("click", (e) => {
        if (e.target === sessionModalEl) {
            sessionModalEl.classList.remove("active");
        }
    });
}

if (loginForm) {
    loginForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        if (loginError) loginError.style.display = "none";
        const email = loginEmail.value.trim();
        const password = loginPassword.value;
        if (!email || !password) {
            if (loginError) {
                loginError.textContent = "Introduce email y contraseña.";
                loginError.style.display = "block";
            }
            return;
        }
    try {
        await login(email, password);
        localStorage.setItem("saiydd_user", email.trim().toLowerCase());
        showApp(email);
        setActiveTab("dashboard");
        setTimeout(() => {
            if (getToken()) {
                try { loadOverview(); } catch (e) { }
            }
        }, 500);
    } catch (err) {
            if (loginError) {
                loginError.textContent = err.message || "Credenciales inválidas.";
                loginError.style.display = "block";
            }
        }
    });
}

if (logoutBtn) {
    logoutBtn.addEventListener("click", () => {
        logout();
        localStorage.removeItem("saiydd_user");
        showLogin();
    });
}

async function loadActivities() {
    try {
        const acts = await getActivities();
        activitiesMap = {};
        acts.forEach(a => {
            activitiesMap[a.id] = a.title;
        });
    } catch (err) {
        console.error(err);
    }
}

async function loadOverview() {
    try {
        const [child, progress] = await Promise.all([
            getChild(TEST_CHILD_ID),
            getProgress(TEST_CHILD_ID)
        ]).catch(err => {
            console.error(err);
            if (err.message === "Sesión expirada") {
                logout();
                localStorage.removeItem("saiydd_user");
                showLogin();
                return [null, null];
            }
            throw err;
        });
        if (!child || !progress) return;
        if (cardTotalSessions) cardTotalSessions.textContent = progress.total_sessions || 0;
        if (cardAvgScore) cardAvgScore.textContent = (progress.average_score || 0) + " %";
        if (cardLastSession) cardLastSession.textContent = formatDateTime(progress.last_activity_at);

        if (alumnosBody) {
            alumnosBody.innerHTML = "";
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td>${child.name}</td>
                <td>${child.avatar}</td>
                <td>${progress.total_sessions || 0}</td>
                <td>${progress.average_score || 0} %</td>
                <td>${formatDateTime(progress.last_activity_at)}</td>
                <td><button class="link-btn" data-action="view-ficha">Ver ficha</button></td>
            `;
            tr.querySelector("[data-action=view-ficha]").addEventListener("click", () => {
                setActiveTab("ficha");
                fillFicha(child, progress);
                renderEvolution();
            });
            alumnosBody.appendChild(tr);
        }

        if (dashboardRecentBody) {
            dashboardRecentBody.innerHTML = "";
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td>${formatDateTime(progress.last_activity_at)}</td>
                <td>${child.name}</td>
                <td>-</td>
                <td>${progress.average_score || 0} %</td>
                <td>${formatSeconds(progress.total_seconds)}</td>
                <td></td>
            `;
            dashboardRecentBody.appendChild(tr);
        }

        fillFicha(child, progress);
        renderEvolution();
    } catch (err) {
        console.error(err);
    }
}

function fillFicha(child, progress) {
    if (fichaChildId) fichaChildId.textContent = child.id;
    if (fichaChildName) fichaChildName.textContent = child.name;
    if (fichaChildAvatar) fichaChildAvatar.textContent = child.avatar;
    if (fichaChildCreated) fichaChildCreated.textContent = formatDateTime(child.created_at);
    if (fichaTotalSessions) fichaTotalSessions.textContent = progress.total_sessions || 0;
    if (fichaAvgScore) fichaAvgScore.textContent = (progress.average_score || 0) + " %";
    if (fichaTotalTime) fichaTotalTime.textContent = formatSeconds(progress.total_seconds);
    if (fichaLastActivity) fichaLastActivity.textContent = formatDateTime(progress.last_activity_at);
}

async function renderEvolution() {
    try {
        const sessions = await getSessions(TEST_CHILD_ID).catch(err => {
            if (err.message === "Sesión expirada") {
                logout();
                localStorage.removeItem("saiydd_user");
                showLogin();
                return [];
            }
            throw err;
        });
        sessionsCache = sessions;
        if (!evolutionChartCanvas) return;
        const labels = sessions.map((s, idx) => "S" + (sessions.length - idx)).reverse();
        const data = sessions.map(s => s.score).reverse();
        if (evolutionChart) {
            evolutionChart.destroy();
        }
        evolutionChart = new Chart(evolutionChartCanvas, {
            type: "line",
            data: {
                labels: labels,
                datasets: [{
                    label: "Puntaje",
                    data: data,
                    borderColor: "#3b82f6",
                    backgroundColor: "rgba(59, 130, 246, 0.2)",
                    tension: 0.3,
                    fill: true
                }]
            },
            options: {
                scales: {
                    y: { beginAtZero: true, max: 100 }
                },
                plugins: {
                    legend: { display: false }
                }
            }
        });
    } catch (err) {
        console.error(err);
    }
}

async function loadHistorial() {
    try {
        await loadActivities();
        const sessions = await getSessions(TEST_CHILD_ID).catch(err => {
            if (err.message === "Sesión expirada") {
                logout();
                localStorage.removeItem("saiydd_user");
                showLogin();
                return [];
            }
            throw err;
        });
        sessionsCache = sessions;
        if (!historialBody) return;
        historialBody.innerHTML = "";
        if (sessions.length === 0) {
            const tr = document.createElement("tr");
            tr.innerHTML = '<td colspan="6" class="table-empty">Sin sesiones</td>';
            historialBody.appendChild(tr);
            return;
        }
        sessions.forEach((s, idx) => {
            const tr = document.createElement("tr");
            const actName = activitiesMap[s.activity_id] || s.activity_id;
            tr.innerHTML = `
                <td>${formatDateTime(s.finished_at)}</td>
                <td>${actName}</td>
                <td>${s.score} %</td>
                <td>${s.duration_seconds}</td>
                <td>${s.interactions ? s.interactions.length : 0}</td>
                <td><button class="link-btn" data-action="ver-detalle" data-idx="${idx}">Ver detalle</button></td>
            `;
            tr.querySelector("[data-action=ver-detalle]").addEventListener("click", () => {
                openSessionDetail(s, idx);
            });
            historialBody.appendChild(tr);
        });
    } catch (err) {
        console.error(err);
    }
}

async function loadSimulatorStatus() {
    if (estadoBackend) {
        estadoBackend.textContent = "Comprobando...";
    }
    if (estadoRojo) {
        estadoRojo.textContent = "Comprobando...";
    }
    try {
        const health = await getHealth();
        if (estadoBackend) {
            estadoBackend.textContent = (health.status || "ok") + " / v" + (health.version || "-");
        }
    } catch (err) {
        if (estadoBackend) {
            estadoBackend.textContent = "No disponible";
        }
    }
    try {
        const rojo = await getRojoTree();
        if (!rojo.ok) {
            if (estadoRojo) estadoRojo.textContent = "No disponible";
            return;
        }
        const raw = rojo.raw;
        const needles = ["Shared", "Events", "SAIyDDRecordSession", "SAIyDDHealthCheck", "ServerScriptService", "ActivityGui", "StarterPlayerScripts"];
        const found = needles.filter(n => raw.indexOf(n) !== -1);
        if (estadoRojo) {
            if (found.length === needles.length) {
                estadoRojo.textContent = "Sincronizado (" + found.length + "/" + needles.length + ")";
            } else {
                estadoRojo.textContent = "Parcial (" + found.length + "/" + needles.length + ")";
            }
        }
    } catch (err) {
        if (estadoRojo) estadoRojo.textContent = "No disponible";
    }
}

function openSessionDetail(session, idx) {
    if (!sessionModalEl) return;
    const actName = activitiesMap[session.activity_id] || session.activity_id;
    if (modalDate) modalDate.textContent = formatDateTime(session.finished_at);
    if (modalActivity) modalActivity.textContent = actName;
    if (modalScore) modalScore.textContent = session.score + " %";
    if (modalDuration) modalDuration.textContent = session.duration_seconds + " s";
    if (interactionList) {
        interactionList.innerHTML = "";
        const interactions = session.interactions || [];
        if (interactions.length === 0) {
            const div = document.createElement("div");
            div.className = "table-empty";
            div.textContent = "Sin interacciones";
            interactionList.appendChild(div);
        } else {
            interactions.forEach((it, i) => {
                const item = document.createElement("div");
                item.className = "interaction-item";
                const statusClass = it.correct ? "interaction-status ok" : "interaction-status bad";
                const statusText = it.correct ? "✓ Acierto" : "✗ Fallo";
                const time = it.response_time_ms !== null && it.response_time_ms !== undefined ? it.response_time_ms + " ms" : "-";
                item.innerHTML = `
                    <div class="interaction-index">#${i + 1}</div>
                    <div>Pregunta ${it.prompt_index + 1} - Opción elegida: ${it.selected_index + 1}</div>
                    <div class="${statusClass}">${statusText}</div>
                    <div>${time}</div>
                `;
                interactionList.appendChild(item);
            });
        }
    }
    sessionModalEl.classList.add("active");
}

function init() {
    const token = getToken();
    if (token && appView && loginView) {
        const user = localStorage.getItem("saiydd_user") || "";
        showApp(user);
        setActiveTab("dashboard");
        setTimeout(() => {
            try { loadOverview(); } catch (e) { }
        }, 150);
    } else {
        showLogin();
    }
}

init();
