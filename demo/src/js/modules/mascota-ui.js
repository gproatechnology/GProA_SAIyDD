export function createMascotaBar(container) {
  const bar = document.createElement("div");
  bar.className = "mascota-bar";
  bar.setAttribute("role", "region");
  bar.setAttribute("aria-label", "Estado de la mascota guía");

  const avatar = document.createElement("div");
  avatar.className = "mascota-avatar";
  avatar.setAttribute("role", "img");
  avatar.setAttribute("aria-label", "Mascota Orion");

  const name = document.createElement("div");
  name.className = "mascota-name";
  name.textContent = "Orion";

  const muteBtn = document.createElement("button");
  muteBtn.type = "button";
  muteBtn.className = "mascota-mute";
  muteBtn.setAttribute("aria-label", "Silenciar voz");
  muteBtn.setAttribute("aria-pressed", "false");

  bar.appendChild(avatar);
  bar.appendChild(name);
  bar.appendChild(muteBtn);
  container.appendChild(bar);

  return { bar, avatar, muteBtn };
}

export function updateMascotaUI(state, ui) {
  const expr = state.expression || "neutral";
  const EXPRESSIONS = {
    neutral: "😊",
    happy: "🥳",
    encourage: "🤩",
    surprise: "😲",
  };
  const EXPRESSION_LABELS = {
    neutral: "feliz y atento",
    happy: "celebrando con entusiasmo",
    encourage: "animándote a seguir",
    surprise: "sorprendido y curioso",
  };

  if (ui?.avatar) {
    ui.avatar.textContent = EXPRESSIONS[expr] || "😊";
    ui.avatar.setAttribute(
      "aria-label",
      `Mascota Orion: ${EXPRESSION_LABELS[expr] || "expresión amigable"}`,
    );
  }
  if (ui?.muteBtn) {
    ui.muteBtn.innerHTML = `<span aria-hidden="true">${state.muted ? "🔇" : "🔊"}</span>`;
    ui.muteBtn.setAttribute(
      "aria-label",
      state.muted ? "Activar voz del asistente" : "Silenciar voz del asistente",
    );
    ui.muteBtn.setAttribute("aria-pressed", state.muted ? "true" : "false");
  }
}
