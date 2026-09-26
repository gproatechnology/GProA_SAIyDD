export const childProfiles = [
  {
    id: 'child_001',
    name: 'Luna',
    age: 5,
    avatar: 'estelar',
    preferences: { topic: 'animales', difficulty: 'easy' },
    createdAt: '2026-07-22T10:00:00Z'
  }
];

export const activities = [
  {
    id: 'act_001',
    title: 'Sonidos de la granja',
    type: 'listening',
    category: 'naturaleza',
    difficulty: 'easy',
    durationSeconds: 120,
    prompts: ['¿Qué animal hace "mu"?', '¿Qué animal hace "oink"?'],
    correctIndices: [0, 1],
    audioAssets: ['cow.mp3', 'pig.mp3']
  },
  {
    id: 'act_002',
    title: 'Colores del arcoíris',
    type: 'visual',
    category: 'artistica',
    difficulty: 'easy',
    durationSeconds: 150,
    prompts: ['Selecciona el color rojo', 'Selecciona el color azul'],
    correctIndices: [0, 2],
    options: ['🔴', '🟢', '🔵', '🟡']
  },
  {
    id: 'act_003',
    title: 'Parejas de frutas',
    type: 'memory',
    category: 'cognitiva',
    difficulty: 'easy',
    durationSeconds: 180,
    prompts: ['Encontrá la pareja de la manzana 🍎', 'Encontrá la pareja del plátano 🍌'],
    pairs: [['🍎','🍎'], ['🍌','🍌']],
    options: ['🍎','🍌','🍇','🍊']
  },
  {
    id: 'act_004',
    title: 'Números del 1 al 3',
    type: 'visual',
    category: 'matematica',
    difficulty: 'easy',
    durationSeconds: 120,
    prompts: ['Selecciona el número 2', 'Selecciona el número 3'],
    correctIndices: [1, 2],
    options: ['1️⃣','2️⃣','3️⃣','4️⃣']
  }
];

export const sessions = [
  {
    id: 'sess_001',
    childId: 'child_001',
    activityId: 'act_001',
    startedAt: '2026-07-22T10:05:00Z',
    finishedAt: '2026-07-22T10:07:00Z',
    score: 80,
    interactions: [
      { promptIndex: 0, selectedIndex: 0, correct: true, responseTimeMs: 3000 },
      { promptIndex: 1, selectedIndex: 1, correct: true, responseTimeMs: 4200 }
    ]
  }
];

export const mascotaConfig = {
  id: 'masc_001',
  name: 'Orion',
  voice: { pitch: 1.3, rate: 0.9, lang: 'es-MX' },
  expressions: ['happy', 'encourage', 'neutral', 'surprise'],
  animationSprites: {
    happy: 'mascota_happy.webp',
    encourage: 'mascota_encourage.webp'
  }
};

export default { childProfiles, activities, sessions, mascotaConfig };
if (typeof window !== 'undefined') {
  window.dataMock = { childProfiles, activities, sessions, mascotaConfig };
}