import { allowAction } from '../utils/rate-limiter.js';

const TILE = 48;
const WORLD_W = 14;
const WORLD_H = 10;

const LEVELS = [
  { id: 'lvl1', name: 'Playa', palette: ['#bde0fe','#a2d2ff','#cdb4db'], collectibles: [{ kind: 'star', x: 5, y: 2 }, { kind: 'letter', x: 9, y: 5 }, { kind: 'star', x: 3, y: 7 }, { kind: 'letter', x: 12, y: 1 }] },
  { id: 'lvl2', name: 'Bosque', palette: ['#d8f3dc','#b7e4c7','#95d5b2'], collectibles: [{ kind: 'star', x: 2, y: 1 }, { kind: 'letter', x: 7, y: 3 }, { kind: 'star', x: 11, y: 6 }, { kind: 'letter', x: 4, y: 8 }] },
  { id: 'lvl3', name: 'Nieve', palette: ['#f0f4f8','#d9e2ec','#bcccdc'], collectibles: [{ kind: 'star', x: 6, y: 4 }, { kind: 'letter', x: 1, y: 5 }, { kind: 'star', x: 10, y: 2 }, { kind: 'letter', x: 8, y: 7 }, { kind: 'star', x: 3, y: 3 }] },
];

function getSaveKey() {
  try {
    const u = new URL(window.location.href);
    const p = u.pathname.replace(/\/+$/, '');
    const parts = p.split('/').filter(Boolean);
    const slug = parts[parts.length - 1] || 'blocks';
    return `saiydd_blocks_${slug}`;
  } catch {
    return 'saiydd_blocks_demo';
  }
}

function loadProgress() {
  try {
    const raw = localStorage.getItem(getSaveKey());
    return raw ? JSON.parse(raw) : { levelIndex: 0, totalStars: 0, totalLetters: 0 };
  } catch {
    return { levelIndex: 0, totalStars: 0, totalLetters: 0 };
  }
}

function saveProgress(state) {
  try {
    localStorage.setItem(getSaveKey(), JSON.stringify(state));
  } catch {
    // ignore storage errors
  }
}

let levelIndex = 0;
let player = { kind: 'player', x: 1, y: Math.floor(WORLD_H / 2) };
let items = [];
let collected = 0;
let completed = false;

function loadLevel() {
  const level = LEVELS[levelIndex];
  player = { kind: 'player', x: 1, y: Math.floor(WORLD_H / 2) };
  items = [{ ...player }, ...level.collectibles.map(c => ({ ...c }))];
  collected = 0;
  completed = false;
}

function inBounds(x, y) {
  return x >= 0 && y >= 0 && x < WORLD_W && y < WORLD_H;
}

function move(dx, dy) {
  if (completed) return;
  if (!allowAction('blocks-move', 30, 60000)) return;
  const nx = player.x + dx;
  const ny = player.y + dy;
  if (!inBounds(nx, ny)) return;
  player.x = nx;
  player.y = ny;
  tick();
}

function tick() {
  for (let i = items.length - 1; i >= 0; i--) {
    const it = items[i];
    if (it.kind === 'player') continue;
    if (it.x === player.x && it.y === player.y) {
      items.splice(i, 1);
      if (it.kind === 'star') {
        collected++;
        showOverlay('¡Estrella! ⭐');
      } else if (it.kind === 'letter') {
        collected++;
        showOverlay('¡Letra! 🔤');
      }
    }
  }
  if (!completed && items.filter(x => x.kind !== 'player').length === 0) {
    completed = true;
    const progress = loadProgress();
    progress.totalStars += collected;
    progress.levelIndex = Math.min(levelIndex + 1, LEVELS.length - 1);
    saveProgress(progress);
    showOverlay('¡Completaste el nivel! 🎉');

    setTimeout(() => {
      if (progress.levelIndex >= LEVELS.length) {
        showOverlay('¡Ganaste todos los niveles! 🏆');
      }
    }, 950);
  }
}

function getItems() {
  return [player, ...items.filter(x => x.kind !== 'player')];
}

let overlayTimer = null;
function showOverlay(msg) {
  const wrap = document.createElement('div');
  wrap.className = 'blocks-overlay';
  wrap.textContent = msg;
  const root = document.getElementById('blocksStage');
  const canvasWrap = root?.querySelector('.blocks-canvas-wrap');
  if (canvasWrap) canvasWrap.appendChild(wrap);
  clearTimeout(overlayTimer);
  overlayTimer = setTimeout(() => wrap.remove(), 900);
}

export function showBlocksWorld({ app, setView }) {
  const section = document.createElement('section');
  section.className = 'screen screen--blocks';
  section.innerHTML = `
    <div class="blocks-wrap">
      <div class="blocks-header">
        <h1>🏖️ Mundo Bloques</h1>
        <div class="help-text">Mové el avatar con las flechas o los botones. Esc = salir.</div>
      </div>
      <div class="blocks-canvas-wrap">
        <canvas id="blocksCanvas" aria-label="Mundo bloques"></canvas>
        <div class="blocks-hud" id="blocksHud">Nivel: - | Coleccionados: 0</div>
      </div>
      <div class="blocks-controls">
        <div class="controls-pad">
          <button type="button" class="control-btn spacer" aria-hidden="true"></button>
          <button type="button" class="control-btn" data-dir="up" aria-label="Arriba">↑</button>
          <button type="button" class="control-btn spacer" aria-hidden="true"></button>
          <button type="button" class="control-btn" data-dir="left" aria-label="Izquierda">←</button>
          <button type="button" class="control-btn" data-dir="down" aria-label="Abajo">↓</button>
          <button type="button" class="control-btn" data-dir="right" aria-label="Derecha">→</button>
        </div>
        <div style="display:flex;flex-direction:column;gap:10px;justify-content:center;">
          <button id="exitBlocks" type="button" class="control-btn" style="background:#ef476f;color:#fff;">Volver</button>
          <button id="nextLevelBtn" type="button" class="control-btn" style="background:#118AB2;color:#fff;" disabled>Siguiente nivel</button>
        </div>
      </div>
      <div id="blocksStage"></div>
    </div>
  `;

  const progress = loadProgress();
  levelIndex = progress.levelIndex;
  loadLevel();

  const canvasEl = section.querySelector('#blocksCanvas');
  const ctx = canvasEl?.getContext('2d');
  const hudEl = section.querySelector('#blocksHud');
  const stageEl = section.querySelector('#blocksStage');
  const nextBtn = section.querySelector('#nextLevelBtn');

  if (!ctx) {
    stageEl.innerHTML = '<p style="color:red">No se pudo iniciar el canvas.</p>';
    app.appendChild(section);
    return;
  }

  function drawBlock(x, y, color, outline = '#222') {
    const px = x * TILE;
    const py = y * TILE;
    const s = TILE;

    ctx.fillStyle = color;
    ctx.fillRect(px, py, s, s);

    ctx.fillStyle = 'rgba(255,255,255,.25)';
    ctx.fillRect(px, py, s, 8);
    ctx.fillRect(px, py, 8, s);

    ctx.fillStyle = 'rgba(0,0,0,.15)';
    ctx.fillRect(px, py + s - 8, s, 8);
    ctx.fillRect(px + s - 8, py, 8, s);

    ctx.strokeStyle = outline;
    ctx.lineWidth = 2;
    ctx.strokeRect(px + 1, py + 1, s - 2, s - 2);
  }

  function drawVoxelPlayer(bx, by) {
    const px = bx * TILE;
    const py = by * TILE;
    const s = TILE;

    ctx.fillStyle = '#ffd166';
    ctx.fillRect(px + 6, py + 6, s - 12, s - 12);
    ctx.strokeStyle = '#222';
    ctx.lineWidth = 2;
    ctx.strokeRect(px + 6, py + 6, s - 12, s - 12);

    ctx.fillStyle = '#222';
    ctx.fillRect(px + 18, py + 18, 8, 8);
    ctx.fillRect(px + 30, py + 18, 8, 8);
    ctx.fillRect(px + 20, py + 34, 16, 6);
  }

  function drawCollectible(bx, by, kind) {
    const px = bx * TILE;
    const py = by * TILE;
    const s = TILE;

    ctx.fillStyle = '#fff';
    ctx.font = `${s - 10}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const symbol = kind === 'star' ? '⭐' : kind === 'letter' ? 'Aa' : '?';
    ctx.fillText(symbol, px + s / 2, py + s / 2);
  }

  function drawSky(palette) {
    const [a, b, c] = palette;
    const grd = ctx.createLinearGradient(0, 0, 0, canvasEl.height);
    grd.addColorStop(0, a);
    grd.addColorStop(0.6, b);
    grd.addColorStop(1, c);
    ctx.fillStyle = grd;
    ctx.fillRect(0, 0, canvasEl.width, canvasEl.height);
  }

  function drawClouds() {
    ctx.fillStyle = 'rgba(255,255,255,.7)';
    ctx.fillRect(60, 20, 140, 30);
    ctx.fillRect(280, 50, 120, 24);
  }

  function render() {
    canvasEl.width = WORLD_W * TILE;
    canvasEl.height = WORLD_H * TILE;
    drawSky(LEVELS[levelIndex].palette);
    drawClouds();

    for (let y = 0; y < WORLD_H; y++) {
      for (let x = 0; x < WORLD_W; x++) {
        const shade = (x + y) % 2 === 0 ? '#7dcea0' : '#76c7a0';
        drawBlock(x, y, shade, '#2f4f4f');
      }
    }

    getItems().forEach((it) => {
      if (it.kind === 'player') drawVoxelPlayer(it.x, it.y);
      else drawCollectible(it.x, it.y, it.kind);
    });
  }

  function updateHud() {
    hudEl.textContent = `Nivel: ${LEVELS[levelIndex].name} | Coleccionados: ${collected}`;
  }

  function renderAll() {
    render();
    updateHud();
  }

  renderAll();

  const keys = new Set();
  const dirs = { ArrowUp: [0, -1], ArrowDown: [0, 1], ArrowLeft: [-1, 0], ArrowRight: [1, 0], w: [0, -1], s: [0, 1], a: [-1, 0], d: [1, 0] };

  function keyLoop() {
    for (const k of keys) {
      const d = dirs[k];
      if (d) {
        move(d[0], d[1]);
        renderAll();
        break;
      }
    }
    requestAnimationFrame(keyLoop);
  }

  section.addEventListener('keydown', (e) => { keys.add(e.key); });
  section.addEventListener('keyup', (e) => keys.delete(e.key));
  requestAnimationFrame(keyLoop);

  section.querySelectorAll('[data-dir]').forEach((btn) => {
    const repeat = () => {
      const d = btn.dataset.dir;
      const m = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] }[d];
      if (m) move(m[0], m[1]);
      btn._timer = requestAnimationFrame(repeat);
      renderAll();
    };
    btn.addEventListener('pointerdown', (e) => { e.preventDefault(); repeat(); });
    btn.addEventListener('pointerup', () => cancelAnimationFrame(btn._timer));
    btn.addEventListener('pointerleave', () => cancelAnimationFrame(btn._timer));
  });

  section.querySelector('#exitBlocks').addEventListener('click', () => {
    keys.clear();
    setView('menu');
  });

  nextBtn.addEventListener('click', () => {
    if (levelIndex + 1 < LEVELS.length) {
      levelIndex++;
      loadLevel();
      saveProgress({ ...loadProgress(), levelIndex });
      renderAll();
      nextBtn.disabled = true;
    }
  });

  section.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') setView('menu');
  });

  window.addEventListener('storage', () => {
    const p = loadProgress();
    if (p.levelIndex > levelIndex) {
      levelIndex = p.levelIndex;
      loadLevel();
      renderAll();
    }
  });

  app.appendChild(section);
}