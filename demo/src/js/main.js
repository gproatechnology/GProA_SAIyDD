import { initApp } from './modules/app.js';

function hideSplash() {
  const el = document.getElementById('splash');
  if (el) el.classList.add('hidden');
}

document.addEventListener('DOMContentLoaded', () => {
  try {
    if (typeof initApp !== 'function') throw new Error('initApp no está disponible');
    initApp();
  } catch (err) {
    console.error('[SaIyDD] initApp failed:', err);
    const app = document.getElementById('app');
    if (app) app.innerHTML = '<p style="color:red">No se pudo iniciar SaIyDD. Recargá la página.</p>';
  } finally {
    hideSplash();
  }
});