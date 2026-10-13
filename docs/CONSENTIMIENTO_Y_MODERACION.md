# Política de Moderación y Consentimiento Parental (Kid-Safe) — SaIyDD

> **Versión:** 1.0 (Fase de Producción)  
> **Ámbito:** Demo Web, Backend FastAPI e Integración Roblox Studio  
> **Marco regulatorio de referencia:** Principios de protección infantil digital (COPPA, GDPR-K, Ley de Protección de Datos Personales).

---

## 1. Filosofía de Moderación: Entorno Cerrado ("Walled Garden")

SaIyDD está diseñado específicamente para niñas y niños de 4 a 8 años. Para erradicar cualquier posibilidad de exposición a contenido inapropiado o dañino, el sistema aplica una arquitectura de **cero generación libre**:

### 1.1 Respuestas Preaprobadas del Asistente (Orion)
* El asistente virtual (`chatbot.js`) no utiliza modelos de lenguaje generativos abiertos no supervisados.
* Opera sobre una **Base de Conocimiento cerrada (`KB`)** con respuestas pedagógicas estrictamente preaprobadas por educadores.
* Si el menor introduce una consulta fuera del catálogo didáctico, el sistema devuelve invariablemente mensajes de guía seguros (*fallback*) que reorientan al juego o al menú.

### 1.2 Actividades Curadas y Sin Entrada Libre
* En el módulo de juego (`juego.js`), las consignas, imágenes, opciones y retroalimentaciones provienen exclusivamente de un catálogo inmutable (`data.js` / `/api/activities`).
* La interacción se limita a selección de botones y pulsaciones táctiles/de teclado. No hay campos de texto libre abiertos durante las dinámicas de juego infantil.

### 1.3 Guardrails de Saneamiento y Limitación de Frecuencia
* **Saneamiento de texto (`sanitize.js`):** Valida cualquier texto de entrada (`isSafeText`, `escapeHtml`, `clampText`), truncando cadenas excesivas y neutralizando caracteres especiales o intentos de inyección.
* **Rate Limiting local (`rate-limiter.js`):** Previene saturación o uso compulsivo en el chat (máximo 10 mensajes/minuto), en la selección de opciones (máximo 20 selecciones/minuto) y en el movimiento por bloques (máximo 30 acciones/minuto).
* **Rate Limiting de servidor (`slowapi`):** Protege los endpoints de autenticación y registro en el backend (10 peticiones/min en login, 5 peticiones/hora en registro).

---

## 2. Consentimiento Parental Informado

El registro y almacenamiento del progreso formativo infantil está sujeto al control absoluto del tutor o padre de familia:

### 2.1 Puerta de Seguridad para Padres (Parental Gate)
* El acceso al **Panel de Padres (`dashboard.js`)** está protegido por una barrera de confirmación mediante **PIN numérico** configurable (`VITE_SAIYDD_PIN`), impidiendo que el menor altere la configuración o exponga datos.

### 2.2 Principio de Transparencia y Minimización de Datos
En el panel se informa explícitamente al tutor sobre los datos recopilados:
* **Datos registrados:**
  1. Alias o nombre de pila del menor y avatar elegido (ej. "Luna", 🐱).
  2. Historial de sesiones didácticas (fecha, duración en segundos, aciertos en la actividad).
  3. Progreso en el mundo de bloques (nivel actual y estrellas coleccionadas).
* **Datos estrictamente NO recopilados:**
  * ❌ NO se solicita dirección, teléfono, correo ni apellidos del menor.
  * ❌ NO se realiza geolocalización de ningún tipo.
  * ❌ NO se recopilan datos biométricos ni grabaciones de audio permanentes (el reconocimiento de voz opera en tiempo real en la memoria volátil del navegador y nunca se transmite a servidores).
  * ❌ NO existen identificadores publicitarios, cookies de seguimiento ni SDKs de terceros.

### 2.3 Mecanismo de Activación y Revocación de Consentimiento
* Mediante el selector interactivo en el Panel de Padres (`consentToggle` vinculado a `consent.js`), el tutor puede:
  * **Otorgar consentimiento:** Se habilita la persistencia local del progreso educativo.
  * **Revocar consentimiento:** Si el tutor desmarca la casilla, el módulo `juego.js` detiene inmediatamente la persistencia de nuevas sesiones en el almacenamiento del dispositivo.

### 2.4 Derecho al Olvido (Borrado Total de Datos)
* El panel incluye la acción **"Borrado total del menor"** (`clearAllChildData()`), que purga de inmediato:
  * Perfil del niño (`saiydd_profile`).
  * Historial de sesiones acumuladas (`saiydd_sessions_*`).
  * Progreso en el panel de control (`saiydd_dashboard_*`).
  * Progreso en mundo bloques (`saiydd_blocks_*`).
* Esta acción restablece el sistema a su estado inicial de primer uso sin dejar rastros residuales.

---

## 3. Seguridad en Integraciones Externas (Roblox Studio)

* Las sesiones registradas desde Roblox viajan a través de un canal seguro autenticado con JWT de tutor emitido por la API de FastAPI.
* La clave secreta de la cuenta de servicio reside exclusivamente en `rojo/server/secrets.lua` (en el entorno del servidor de Roblox Studio, jamás visible en el cliente Luau de los jugadores).
* Las sesiones registradas respetan las mismas restricciones de minimización de datos: únicamente identificador del perfil, ID de actividad, porcentaje de aciertos y tiempo de sesión.
