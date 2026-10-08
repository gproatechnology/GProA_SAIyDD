import mascota from "./mascota.js";
import { createMascotaBar, updateMascotaUI } from "./mascota-ui.js";
import { api } from "./api.js";
import { clampText } from "../utils/sanitize.js";
import { allowAction } from "../utils/rate-limiter.js";

function renderPrompt(container, prompt, opts, onSelect) {
  const p = document.createElement("p");
  p.className = "juego-prompt";
  p.textContent = prompt;
  container.appendChild(p);

  const row = document.createElement("div");
  row.className = "juego-options";
  opts.forEach((opt, i) => {
    const b = document.createElement("button");
    b.type = "button";
    b.textContent = opt;
    b.setAttribute("data-index", String(i));
    b.addEventListener("click", () => onSelect(i));
    row.appendChild(b);
  });
  container.appendChild(row);
}

function showResult(container, correct, correctAnswer, mascotaUI) {
  const msg = document.createElement("div");
  msg.className = "juego-result";
  if (correct) {
    msg.textContent = "¡Muy bien! 🎉";
    msg.className += " juego-result--ok";
    mascota.setExpression("happy");
    mascota.say("¡Muy bien!", { pitch: 1.5 });
  } else {
    msg.textContent = correctAnswer
      ? `Ups, la correcta era ${correctAnswer}. Intenta de nuevo.`
      : "Ups. Intenta de nuevo.";
    msg.className += " juego-result--fail";
    mascota.setExpression("encourage");
    mascota.say("Ups, intenta de nuevo.", { pitch: 0.9 });
  }
  container.appendChild(msg);
  updateMascotaUI(mascota, mascotaUI);
}

function localStorageKey() {
  try {
    const u = new URL(window.location.href);
    const p = u.pathname.replace(/\/+$/, "");
    return `saiydd_sessions_${p.split("/").filter(Boolean).pop() || "demo"}`;
  } catch {
    return "saiydd_sessions_demo";
  }
}

function loadSessions() {
  try {
    const raw = localStorage.getItem(localStorageKey());
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveSession(session) {
  try {
    const list = loadSessions();
    list.push(session);
    localStorage.setItem(localStorageKey(), JSON.stringify(list));
  } catch {
    // ignore
  }
}

export async function showJuego({ app, activeChild, setView }) {
  mascota.init();
  const section = document.createElement("section");
  section.className = "screen screen--juego";

  const body = document.createElement("div");
  body.className = "juego-body";
  body.setAttribute("aria-live", "polite");
  body.textContent = "Cargando actividades…";

  const mascotaHeader = document.createElement("header");
  mascotaHeader.className = "mascota-header";
  section.appendChild(mascotaHeader);

  const mascotaUI = createMascotaBar(mascotaHeader);
  updateMascotaUI(mascota, mascotaUI);
  mascotaUI.muteBtn.addEventListener("click", () =>
    updateMascotaUI(mascota, mascotaUI),
  );

  const header = document.createElement("header");
  header.innerHTML = `<h1>Juego</h1><button id="backBtn" type="button">Volver</button>`;
  section.appendChild(header);
  section.appendChild(body);
  app.appendChild(section);

  section.querySelector("#backBtn").addEventListener("click", () => {
    persistSession();
    mascota.stop();
    setView("menu");
  });

  let activities = [];
  try {
    activities = await api.getActivities();
  } catch {
    activities = [];
  }

  if (!activities.length) {
    body.innerHTML = "<p>No pudimos cargar las actividades. Volvé al menú.</p>";
    return;
  }

  let activityIndex = 0;
  let step = 0;
  let score = 0;
  const startedAt = new Date().toISOString();
  let startTime = Date.now();

  function current() {
    return activities[activityIndex] || null;
  }

  function totalSteps() {
    const act = current();
    return act?.prompts?.length || 0;
  }

  function totalActivities() {
    return activities.length;
  }

  function persistSession() {
    const act = current();
    if (!act) return;
    saveSession({
      id: `sess_${Date.now().toString(36)}`,
      childId: activeChild?.id || "child_001",
      activityId: act.id,
      startedAt,
      finishedAt: new Date().toISOString(),
      score,
      durationSeconds: Math.round((Date.now() - startTime) / 1000),
      interactions: [],
    });
  }

  function renderStep() {
    body.innerHTML = "";
    const act = current();
    if (!act || activityIndex >= totalActivities()) {
      persistSession();
      body.innerHTML = `<p>Terminaste todas las actividades. Aciertos: ${score}</p><button id="backBtn" type="button">Volver</button>`;
      body
        .querySelector("#backBtn")
        .addEventListener("click", () => setView("menu"));
      mascota.setExpression("happy");
      updateMascotaUI(mascota, mascotaUI);
      return;
    }
    if (step >= totalSteps()) {
      activityIndex++;
      step = 0;
      renderStep();
      return;
    }

    const opts = act.options || [];
    renderPrompt(
      body,
      act.prompts[step],
      opts.map((o) => (typeof o === "string" ? clampText(o) : o)),
      (selectedIndex) => {
        if (!allowAction("juego-select", 20, 60000)) {
          showResult(body, false, null, mascotaUI);
          return;
        }
        api
          .submitAnswer(act.id, step, selectedIndex)
          .then(({ correct, correctOption }) => {
            if (correct) score++;
            showResult(body, correct, correctOption, mascotaUI);
            step++;
            setTimeout(renderStep, 1200);
          });
      },
    );
  }

  renderStep();
}
