import mascota from './mascota.js';
import { createMascotaBar, updateMascotaUI } from './mascota-ui.js';

const PIN_DEFAULT = '1234';

export function showBienvenida({ app, setView, saveProfile }) {
  const card = document.createElement('section');
  card.className = 'screen screen--bienvenida screen--login';

  const saved = (() => {
    try {
      const raw = localStorage.getItem('saiydd_profile');
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  })();

  if (saved?.name && saved?.avatar) {
    card.innerHTML = `
      <h1>Bienvenido de nuevo, ${saved.name}</h1>
      <p>Elegí tu avatar para continuar</p>
      <header class="mascota-header"></header>
      <div class="avatars"></div>
      <button id="startBtn" class="btn btn-primary">Entrar</button>
      <button id="resetProfileBtn" type="button" class="btn btn-outline" style="margin-top:10px;">Cambiar perfil</button>
    `;
  } else {
    card.innerHTML = `
      <h1>Crear perfil</h1>
      <p>Escribí tu nombre y elegí un avatar</p>
      <div class="login-form">
        <label for="childName">Nombre</label>
        <input id="childName" type="text" autocomplete="off" placeholder="Tu nombre" maxlength="20" />
      </div>
      <header class="mascota-header"></header>
      <div class="avatars"></div>
      <button id="startBtn" class="btn btn-primary" disabled>Entrar</button>
    `;
  }

  const mascotaUI = createMascotaBar(card.querySelector('.mascota-header'));
  updateMascotaUI(mascota, mascotaUI);
  mascotaUI.muteBtn.addEventListener('click', () => updateMascotaUI(mascota, mascotaUI));

  const avatars = ['🐱', '🐶', '🐰', '🦁'];
  const avatarsContainer = card.querySelector('.avatars');
  avatarsContainer.innerHTML = avatars.map((a, i) => `<button type="button" data-avatar="${a}" aria-label="Avatar ${i+1}">${a}</button>`).join('');
  card.querySelectorAll('[data-avatar]').forEach(b => b.addEventListener('click', (e) => {
    card.querySelectorAll('[data-avatar]').forEach(x => x.classList.remove('is-selected'));
    e.currentTarget.classList.add('is-selected');
  }));

  const startBtn = card.querySelector('#startBtn');
  const nameInput = card.querySelector('#childName');

  function canStart() {
    const selected = card.querySelector('[data-avatar].is-selected');
    if (!selected) return false;
    if (nameInput) {
      const name = nameInput.value.trim();
      return name.length >= 1;
    }
    return true;
  }

  const validate = () => {
    startBtn.disabled = !canStart();
  };

  if (nameInput) {
    nameInput.addEventListener('input', validate);
    nameInput.focus();
  }

  startBtn.addEventListener('click', () => {
    const selected = card.querySelector('[data-avatar].is-selected');
    if (!selected) return;

    const avatar = selected.dataset.avatar;
    const name = nameInput ? nameInput.value.trim() : (saved?.name || 'Amigo');

    const profile = {
      id: saved?.id || `child_${Date.now().toString(36)}`,
      name,
      avatar,
      preferences: saved?.preferences || { topic: 'animales', difficulty: 'easy' },
      createdAt: saved?.createdAt || new Date().toISOString(),
    };

    saveProfile?.(profile);
    app.setAttribute('data-child-name', profile.name);
    setView('menu');
  });

  const resetBtn = card.querySelector('#resetProfileBtn');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      localStorage.removeItem('saiydd_profile');
      setView('login');
    });
  }

  app.appendChild(card);
}