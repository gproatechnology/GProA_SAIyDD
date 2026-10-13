import mascota from "./mascota.js";
import { createMascotaBar, updateMascotaUI } from "./mascota-ui.js";

function localStorageKey() {
  try {
    const u = new URL(window.location.href);
    const p = u.pathname.replace(/\/+$/, "");
    const slug = p.split("/").filter(Boolean).pop() || "demo";
    return `saiydd_dashboard_${slug}`;
  } catch {
    return "saiydd_dashboard_demo";
  }
}

function loadProgress() {
  try {
    const raw = localStorage.getItem(localStorageKey());
    return raw ? JSON.parse(raw) : { sessions: [], totalTimeSeconds: 0 };
  } catch {
    return { sessions: [], totalTimeSeconds: 0 };
  }
}

function saveProgress(progress) {
  try {
    localStorage.setItem(localStorageKey(), JSON.stringify(progress));
  } catch {
    // ignore
  }
}

function formatTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}m ${s.toString().padStart(2, "0")}s`;
}

import { validatePin, PIN_FROM_ENV } from "../config.js";
import {
  getConsentStatus,
  setConsent,
  clearAllChildData,
} from "../utils/consent.js";

function askPin() {
  const hint = PIN_FROM_ENV ? "" : " (demo)";
  const code = prompt(`Ingresá el PIN de padres${hint}:`);
  if (code === null) return false;
  return validatePin(code);
}

export function showDashboard({ app, setView }) {
  const section = document.createElement("section");
  section.className = "screen screen--dashboard";
  section.innerHTML = `
    <header>
      <h1>Panel de padres</h1>
      <div class="mascota-bar"></div>
      <button id="backBtn" type="button" aria-label="Volver al menú principal">Volver</button>
    </header>
    <div class="dashboard" id="dashboard" role="region" aria-label="Resumen de progreso del niño"></div>
    <div class="dashboard-actions" role="group" aria-label="Acciones del panel">
      <button id="exportBtn" type="button" aria-label="Exportar datos de progreso en formato JSON">Exportar JSON</button>
      <button id="resetBtn" type="button" aria-label="Borrar historial y progreso acumulado" style="background:#ef476f;color:#fff;">Borrar progreso</button>
    </div>
    <div class="dashboard-consent" role="region" aria-labelledby="consentTitle">
      <h2 id="consentTitle">🛡️ Consentimiento Parental y Privacidad Kid-Safe</h2>
      <div id="consentBadge" class="consent-status-badge"></div>
      <p id="consentDesc" style="font-size:0.9rem;color:var(--color-text-muted);">
        SaIyDD cumple con directrices de privacidad infantil (COPPA y protección de datos). Los datos registrados se limitan a avances pedagógicos locales del perfil seleccionado.
      </p>
      <ul class="consent-info-list">
        <li><strong>Datos guardados:</strong> alias/avatar, actividades completadas y aciertos.</li>
        <li><strong>Protección garantizada:</strong> sin anuncios, sin rastreadores externos, sin geolocalización ni retención de grabaciones de voz.</li>
      </ul>
      <div class="consent-controls">
        <label style="display:flex;align-items:center;gap:8px;cursor:pointer;font-weight:600;">
          <input type="checkbox" id="consentToggle" style="width:18px;height:18px;cursor:pointer;" />
          <span>Autorizar registro de progreso y sesiones</span>
        </label>
        <button id="wipeAllBtn" type="button" style="background:#6c757d;color:#fff;font-size:0.85rem;" aria-label="Eliminar todos los datos del menor (derecho al olvido)">
          Borrado total del menor
        </button>
      </div>
    </div>
  `;

  const existing = section.querySelector(".mascota-bar");
  const header = section.querySelector("header");
  const mascotaUI = {};
  const bar = createMascotaBar(header);
  Object.assign(mascotaUI, bar);
  if (existing) existing.remove();
  updateMascotaUI(mascota, mascotaUI);
  mascotaUI.muteBtn.addEventListener("click", () =>
    updateMascotaUI(mascota, mascotaUI),
  );

  const dash = section.querySelector("#dashboard");

  function renderStats() {
    const progress = loadProgress();
    const total = progress.sessions.length;
    const avg = total
      ? Math.round(
          progress.sessions.reduce((a, s) => a + (s.score || 0), 0) / total,
        )
      : 0;

    const stats = [
      { label: "Sesiones", value: String(total) },
      { label: "Aciertos", value: avg ? `${avg}%` : "—" },
      { label: "Tiempo", value: formatTime(progress.totalTimeSeconds || 0) },
    ];
    dash.innerHTML = stats
      .map(
        (s) => `<div class="stat"><h3>${s.value}</h3><p>${s.label}</p></div>`,
      )
      .join("");
  }

  const granted = askPin();
  if (!granted) {
    dash.innerHTML =
      '<p role="alert">Acceso restringido. Volvé cuando tengas el PIN.</p>';
    section
      .querySelector("#backBtn")
      .addEventListener("click", () => setView("menu"));
    app.appendChild(section);
    return;
  }

  renderStats();
  mascota.setExpression("encourage");
  updateMascotaUI(mascota, mascotaUI);

  const consentToggle = section.querySelector("#consentToggle");
  const consentBadge = section.querySelector("#consentBadge");
  const wipeAllBtn = section.querySelector("#wipeAllBtn");

  function updateConsentView() {
    const status = getConsentStatus();
    consentToggle.checked = status.granted;
    if (status.granted) {
      consentBadge.textContent = "Estado: Consentimiento otorgado ✅";
      consentBadge.className = "consent-status-badge is-granted";
    } else {
      consentBadge.textContent =
        "Estado: Registro deshabilitado / Pendiente ⏸️";
      consentBadge.className = "consent-status-badge is-revoked";
    }
  }

  updateConsentView();

  consentToggle.addEventListener("change", (e) => {
    setConsent(e.target.checked);
    updateConsentView();
  });

  wipeAllBtn.addEventListener("click", () => {
    if (
      confirm(
        "¿Estás seguro de que deseas eliminar TODOS los datos del menor (perfil, sesiones y progreso)? Esta acción no se puede deshacer.",
      )
    ) {
      clearAllChildData({ preserveConsent: true });
      renderStats();
      alert("Todos los datos del perfil y sesiones han sido eliminados.");
      setView("login");
    }
  });

  section.querySelector("#backBtn").addEventListener("click", () => {
    mascota.stop();
    setView("menu");
  });
  section.querySelector("#exportBtn").addEventListener("click", () => {
    const progress = loadProgress();
    const blob = new Blob([JSON.stringify(progress, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "saiydd-progreso.json";
    a.click();
    URL.revokeObjectURL(url);
  });
  section.querySelector("#resetBtn").addEventListener("click", () => {
    if (confirm("¿Borrar todo el progreso local?")) {
      saveProgress({ sessions: [], totalTimeSeconds: 0 });
      renderStats();
    }
  });

  app.appendChild(section);
}
