import mascota from './mascota.js';
import { createMascotaBar, updateMascotaUI } from './mascota-ui.js';

export function showMenu({ app, setView }) {
  const section = document.createElement('section');
  section.className = 'screen screen--menu';
  section.innerHTML = `
    <header>
      <h1>Menú</h1>
      <div class="mascota-bar"></div>
      <button id="chatbotBtn" class="btn btn-outline">Chat</button>
    </header>
    <div class="menu-grid"></div>
  `;

  const mascotaUI = {};
  const header = section.querySelector('header');
  const existingBar = section.querySelector('.mascota-bar');
  if (existingBar) {
    const bar = createMascotaBar(header);
    Object.assign(mascotaUI, bar);
    existingBar.remove();
  }

  updateMascotaUI(mascota, mascotaUI);
  mascotaUI.muteBtn?.addEventListener('click', () => updateMascotaUI(mascota, mascotaUI));

  const items = [
    { label: 'Juego', icon: '🎮', view: 'juego' },
    { label: 'Lección', icon: '📚', view: 'juego' },
    { label: 'Mundo Bloques', icon: '🧱', view: 'bloques' },
    { label: 'Para padres', icon: '🔒', view: 'dashboard' },
  ];
  const grid = section.querySelector('.menu-grid');
  grid.innerHTML = items.map(i => `<button type="button" data-view="${i.view}">${i.icon}<span>${i.label}</span></button>`).join('');
  grid.querySelectorAll('[data-view]').forEach(b => b.addEventListener('click', () => setView(b.dataset.view)));
  section.querySelector('#chatbotBtn').addEventListener('click', () => setView('chatbot'));
  app.appendChild(section);
}