export function createMascotaBar(container, opts = {}) {
  const bar = document.createElement('div');
  bar.className = 'mascota-bar';

  const avatar = document.createElement('div');
  avatar.className = 'mascota-avatar';
  avatar.setAttribute('aria-label', 'Orion');

  const name = document.createElement('div');
  name.className = 'mascota-name';
  name.textContent = 'Orion';

  const muteBtn = document.createElement('button');
  muteBtn.type = 'button';
  muteBtn.className = 'mascota-mute';
  muteBtn.setAttribute('aria-label', 'Silenciar voz');

  bar.appendChild(avatar);
  bar.appendChild(name);
  bar.appendChild(muteBtn);
  container.appendChild(bar);

  return { bar, avatar, muteBtn };
}

export function updateMascotaUI(state, ui) {
  const expr = state.expression || 'neutral';
  const EXPRESSIONS = { neutral: '😊', happy: '🥳', encourage: '🤩', surprise: '😲' };
  if (ui?.avatar) ui.avatar.textContent = EXPRESSIONS[expr] || '😊';
  if (ui?.muteBtn) {
    ui.muteBtn.textContent = state.muted ? '🔇' : '🔊';
    ui.muteBtn.setAttribute('aria-label', state.muted ? 'Activar voz' : 'Silenciar voz');
  }
}