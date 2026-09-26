import mascota from './mascota.js';
import { createMascotaBar, updateMascotaUI } from './mascota-ui.js';

function localStorageKey() {
  try {
    const u = new URL(window.location.href);
    const p = u.pathname.replace(/\/+$/, '');
    const slug = p.split('/').filter(Boolean).pop() || 'demo';
    return `saiydd_dashboard_${slug}`;
  } catch {
    return 'saiydd_dashboard_demo';
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
  return `${m}m ${s.toString().padStart(2, '0')}s`;
}

const PIN_DEFAULT = '1234';
function askPin() {
  const code = prompt('Ingresá el PIN de padres (demo: 1234):');
  if (code === null) return false;
  return String(code).trim() === PIN_DEFAULT;
}

export function showDashboard({ app, setView }) {
  const section = document.createElement('section');
  section.className = 'screen screen--dashboard';
  section.innerHTML = `
    <header>
      <h1>Panel de padres</h1>
      <div class="mascota-bar"></div>
      <button id="backBtn" type="button">Volver</button>
    </header>
    <div class="dashboard" id="dashboard"></div>
    <div class="dashboard-actions">
      <button id="exportBtn" type="button">Exportar JSON</button>
      <button id="resetBtn" type="button" style="background:#ef476f;color:#fff;">Borrar progreso</button>
    </div>
  `;

  const existing = section.querySelector('.mascota-bar');
  const header = section.querySelector('header');
  const mascotaUI = {};
  const bar = createMascotaBar(header);
  Object.assign(mascotaUI, bar);
  if (existing) existing.remove();
  updateMascotaUI(mascota, mascotaUI);
  mascotaUI.muteBtn.addEventListener('click', () => updateMascotaUI(mascota, mascotaUI));

  const dash = section.querySelector('#dashboard');

  function renderStats() {
    const progress = loadProgress();
    const total = progress.sessions.length;
    const avg = total ? Math.round(progress.sessions.reduce((a, s) => a + (s.score || 0), 0) / total) : 0;

    const stats = [
      { label: 'Sesiones', value: String(total) },
      { label: 'Aciertos', value: avg ? `${avg}%` : '—' },
      { label: 'Tiempo', value: formatTime(progress.totalTimeSeconds || 0) },
    ];
    dash.innerHTML = stats.map(s => `<div class="stat"><h3>${s.value}</h3><p>${s.label}</p></div>`).join('');
  }

  const granted = askPin();
  if (!granted) {
    dash.innerHTML = '<p>Acceso restringido. Volvé cuando tengas el PIN.</p>';
    section.querySelector('#backBtn').addEventListener('click', () => setView('menu'));
    app.appendChild(section);
    return;
  }

  renderStats();
  mascota.setExpression('encourage');
  updateMascotaUI(mascota, mascotaUI);

  section.querySelector('#backBtn').addEventListener('click', () => { mascota.stop(); setView('menu'); });
  section.querySelector('#exportBtn').addEventListener('click', () => {
    const progress = loadProgress();
    const blob = new Blob([JSON.stringify(progress, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'saiydd-progreso.json';
    a.click();
    URL.revokeObjectURL(url);
  });
  section.querySelector('#resetBtn').addEventListener('click', () => {
    if (confirm('¿Borrar todo el progreso local?')) {
      saveProgress({ sessions: [], totalTimeSeconds: 0 });
      renderStats();
    }
  });

  app.appendChild(section);
}