const DOC_CONTENT = [
  {
    id: 'introduccion',
    title: 'Introducción',
    html: `
      <p>SaIyDD es una <strong>demo educativa infantil</strong> diseñada para infantes de 4 a 8 años. Combina una <strong>mascota guía con voz</strong>, actividades gamificadas y un panel de progreso para padres, siempre dentro de límites <strong>kid-safe</strong>.</p>
      <div class="grid grid-3">
        <div class="card"><h4>¿Qué es</h4><p>Asistente de aprendizaje inclusivo con IA, voz y juegos adaptativos.</p></div>
        <div class="card"><h4>Para qué sirve</h4><p>Fomentar el aprendizaje temprano con interacciones seguras y estimulantes.</p></div>
        <div class="card"><h4>Cómo funciona</h4><p>El niño elige un avatar, juega actividades cortas y recibe retroalimentación audible.</p></div>
      </div>
      <div class="note">Esta es una <strong>demo funcional con datos sintéticos</strong>: la interacción por voz y los juegos son reales, pero el backend seguro y la persistencia remota requieren infraestructura/producto aparte.</div>`
  },
  {
    id: 'acceso',
    title: 'Acceso (bienvenida)',
    html: `
      <ol class="steps">
        <li>Abrí la demo de SaIyDD desde la web principal o directamente en <code>proyectos/saiydd/demo/</code>.</li>
        <li>En la pantalla de bienvenida, elegí tu <strong>avatar</strong> tocando uno de los botones grandes.</li>
        <li>Pulsá <strong>Empezar</strong> para ingresar al menú principal.</li>
      </ol>
      <div class="note">La experiencia está pensada para tacto/click y voz; no requiere lectura avanzada.</div>`
  },
  {
    id: 'mascota',
    title: 'Mascota guía (Orion)',
    html: `
      <p>Orion es el avatar guía. Acompaña al niño con:</p>
      <ul>
        <li><strong>Voz amigable:</strong> usa Web Speech API para leer indicaciones.</li>
        <li><strong>Expresiones:</strong> estados <em>happy</em>, <em>encourage</em>, <em>neutral</em>, <em>surprise</em>.</li>
        <li><strong>Interacción limitada:</strong> responde solo desde catálogos preaprobados kid-safe.</li>
      </ul>
      <div class="note">Si el navegador no soporta voz, Orion sigue funcionando en modo silencioso con texto e iconos.</div>`
  },
  {
    id: 'menu',
    title: 'Menú principal',
    html: `
      <p>El menú presenta opciones grandes y claras:</p>
      <div class="grid grid-3">
        <div class="card"><h4>Juego</h4><p>Actividad interactiva con preguntas y respuestas inmediatas.</p></div>
        <div class="card"><h4>Lección</h4><p>Contenido educativo breve con refuerzo auditivo y visual.</p></div>
        <div class="card"><h4>Para padres</h4><p>Panel oculto con métricas de progreso.</p></div>
      </div>
      <p>También podés abrir el <strong>Chat</strong> para escribir o usar el micrófono.</p>`
  },
  {
    id: 'juego',
    title: 'Juego / Aprendizaje',
    html: `
      <p>El módulo de juego muestra <strong>actividades cortas</strong> (menos de 3 minutos) con:</p>
      <ol class="steps">
        <li><strong>Prompt claro:</strong> pregunta simple con opciones grandes.</li>
        <li><strong>Selección:</strong> tocá la opción correcta.</li>
        <li><strong>Retroalimentación:</strong> sonido y mensaje visible tras cada elección.</li>
        <li><strong>Progreso:</strong> al finalizar se muestra la cantidad de aciertos.</li>
      </ol>
      <div class="note">Las respuestas se validan contra listas blancas definidas en <code>data.js</code>. No hay generación libre.</div>`
  },
  {
    id: 'chatbot',
    title: 'Asistente (chatbot)',
    html: `
      <p>El asistente permite interactuar por <strong>texto o voz</strong>:</p>
      <ul>
        <li><strong>Entrada de texto:</strong> escribí y enviá con el botón o Enter.</li>
        <li><strong>Micrófono:</strong> usar reconocimiento de voz cuando el navegador lo permita.</li>
        <li><strong>Respuestas:</strong> siempre desde repertorio fijo, sin contenido abierto.</li>
      </ul>
      <div class="note">El chatbot es una demo local. En producción, las respuestas pasarían por un endpoint moderado.</div>`
  },
  {
    id: 'voz',
    title: 'Interacción por voz',
    html: `
      <p>SaIyDD puede usar dos APIs nativas cuando están disponibles:</p>
      <div class="grid grid-2">
        <div class="card"><h4>Web Speech API (TTS)</h4><p>Lectura de indicaciones con voz en español, pitch y rate ajustados para niños.</p></div>
        <div class="card"><h4>Web Speech API (STT)</h4><p>Reconocimiento de comandos simples, limitado a frases del dominio educativo.</p></div>
      </div>
      <div class="note">Si la API no está disponible, la app continúa en modo táctil/visual sin errores.</div>`
  },
  {
    id: 'dashboard',
    title: 'Panel de padres',
    html: `
      <p>El panel oculto muestra métricas básicas de progreso:</p>
      <ul>
        <li><strong>Sesiones</strong> realizadas.</li>
        <li><strong>Aciertos</strong> promedio.</li>
        <li><strong>Tiempo</strong> estimado de uso.</li>
      </ul>
      <p>En futuras versiones se agregará acceso por <strong>PIN o token temporal</strong> y exportación de reportes.</p>`
  },
  {
    id: 'seguridad',
    title: 'Seguridad y privacidad',
    html: `
      <p>SaIyDD aplica principios <strong>kid-safe</strong> desde el diseño:</p>
      <ul>
        <li><strong>Sin PII del menor</strong> en servidores durante la demo.</li>
        <li><strong>Lista blanca</strong> de respuestas y actividades permitidas.</li>
        <li><strong>Rate limiting</strong> sugerido: máximo 10 interacciones por minuto.</li>
        <li><strong>Cumplimiento COPPA/GDPR-K</strong> en fase demo.</li>
      </ul>
      <div class="note">No se envían logs con información personal a terceros. Todo el progreso se guarda localmente.</div>`
  },
  {
    id: 'alcance',
    title: 'Alcance y limitaciones',
    html: `
      <p>La versión actual incluye:</p>
      <ul>
        <li>Selección de avatar y navegación táctil.</li>
        <li>Actividad demo con validación de respuestas.</li>
        <li>Chatbot local con respuestas predefinidas.</li>
        <li>Dashboard padres con métricas desde <code>data.js</code>.</li>
        <li>Capa <code>api.js</code> mock lista para backend.</li>
      </ul>
      <div class="note">Quedan pendientes: assets de audio reales, más actividades, persistencia remota y moderación automática.</div>`
  },
  {
    id: 'qa',
    title: 'Preguntas frecuentes',
    items: [
      {
        question: '¿SaIyDD reemplaza un producto educativo real?',
        answer: 'No. Es una demo para validar interacción infantil, TTS/voz y arquitectura modular. La versión productiva necesita backend, moderación y cumplimiento normativo completo.'
      },
      {
        question: '¿Se guardan datos de los niños?',
        answer: 'En la demo, solo localmente en el navegador. No se envía información personal a servidores.'
      },
      {
        question: '¿Qué pasa si el navegador no soporta voz?',
        answer: 'La app continúa en modo visual/táctil sin errores. La voz es optativa.'
      },
      {
        question: '¿Cómo se agrega una nueva actividad?',
        answer: 'Agregala en <code>src/js/data/data.js</code> dentro de <code>activities</code> con <code>prompts</code>, <code>options</code> e <code>correctIndices</code>.'
      }
    ]
  },
  {
    id: 'soporte',
    title: 'Soporte',
    html: '<p>Para soporte técnico, contactá a <strong>admin@gproatechnology.com</strong> o llamá al <strong>+52 1 468 120 8570</strong>.</p>'
  }
];

function stripTags(html) {
  const tmp = document.createElement('div');
  tmp.innerHTML = html || '';
  return tmp.textContent || '';
}

export function buildToc() {
  const toc = document.getElementById('toc');
  if (!toc) return;

  const title = toc.querySelector('h4');
  toc.innerHTML = '';
  if (title) toc.appendChild(title);

  DOC_CONTENT.forEach((section) => {
    const link = document.createElement('a');
    link.href = `#${section.id}`;
    link.textContent = section.title;
    link.dataset.target = section.id;
    toc.appendChild(link);
  });
}

export function buildDocSections() {
  const container = document.getElementById('inicio');
  if (!container) return;

  container.innerHTML = '';
  document.getElementById('docLoader')?.remove();

  DOC_CONTENT.forEach((section) => {
    const sectionEl = document.createElement('section');
    sectionEl.className = 'doc-section';
    sectionEl.id = section.id;

    let searchText = `${section.title} ${stripTags(section.html)}`;
    if (section.items) {
      section.items.forEach((item) => {
        searchText += ` ${item.question} ${item.answer}`;
      });
    }
    sectionEl.dataset.search = searchText.toLowerCase();

    const h2 = document.createElement('h2');
    h2.textContent = section.title;
    sectionEl.appendChild(h2);

    if (section.html) {
      const wrapper = document.createElement('div');
      wrapper.innerHTML = section.html;
      sectionEl.appendChild(wrapper);
    }

    if (section.items) {
      section.items.forEach((item) => {
        const details = document.createElement('details');
        details.innerHTML = `
          <summary>${item.question}</summary>
          <p>${item.answer}</p>
        `;
        sectionEl.appendChild(details);
      });
    }

    container.appendChild(sectionEl);
  });
}

export { DOC_CONTENT };