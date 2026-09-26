import data from '../data/data.js';
import { showBienvenida } from './bienvenida.js';
import { showMenu } from './menu.js';
import { showChatbot } from './chatbot.js';
import { showDashboard } from './dashboard.js';
import { showJuego } from './juego.js';
import { showBlocksWorld } from './blocks-world.js';

const PROFILE_KEY = 'saiydd_profile';
const profileFromStorage = () => {
  try {
    const raw = localStorage.getItem(PROFILE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
};
const saveProfile = (profile) => {
  try {
    localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
  } catch {
    // ignore
  }
};

let currentView = 'login';
let activeChild = profileFromStorage() || data.childProfiles[0];

const views = {
  login: showBienvenida,
  bienvenida: showBienvenida,
  menu: showMenu,
  chatbot: showChatbot,
  dashboard: showDashboard,
  juego: showJuego,
  bloques: showBlocksWorld,
};

function render() {
  const app = document.getElementById('app');
  const fn = views[currentView];
  app.innerHTML = '';
  fn({ app, activeChild, setView, saveProfile });
}

function setView(view) {
  currentView = view;
  render();
}

export function initApp() {
  render();
}