
## 0. Preparación (completado)
- Dir: SAIyDD (ok)
- pytest: 14/14 passed
- Backend corriendo: NO (offline) — pendiente arrancar
- backend/.env: NO (existe .env.example)
- demo/.env: NO (existe .env.example)
- %TEMP%\saiydd-state.json existe (token puede expirar)
- rojo/server/secrets.lua en .gitignore; plantilla rojo/server/secrets.example.lua versionada (ok)
- demo tests: 26/26 passed
---


## 1. CORS (revisión)
- Backend: verificar app/main.py y core/config.py
- Estados actuales: no visibles sin leer archivos. Pendiente lectura.
---


## 1. CORS
- config.cors_origins: 'http://localhost:5174' (lista via split)
- main: CORSMiddleware allow_origins=settings.cors_origins_list, allow_methods=['GET','POST'], allow_headers=['*']
- NOTA: allow_credentials no está seteado (por defecto False). No usa ['*'] con credentials=True. OK para dev.
- Esperados: localhost:5174 (Vite). Pendiente validar prod/orígenes Rojo/Studio HTTP. Estado: OK (dev).
---


## 2. JWT/Autenticación
- HS256, secreto configurable (settings.jwt_secret), exp configurable (access_token_expire_minutes default 60)
- Errores genéricos: 'Token expirado', 'Token inválido', 'Se requiere autenticación', 'Acceso denegado: se requiere rol tutor' — sin stack traces expuestos
- Endpoints protegidos: POST /api/children, POST /api/sessions, GET /api/children/{id}, GET /api/children/{id}/progress (via require_tutor)
- Públicos: /api/health, /api/activities, POST /api/auth/register, POST /api/auth/login
- Rate limiting: slowapi aplicado (ver main/routes). Token tutor de demo/token de Studio puede expirar.
- Rojo: secrets.lua con email/password; server main.server.lua hace login y cache JWT (según SDD). Pendiente verificar mensajes de error no filtran secretos.
- Estado: OK (dev). Requiere rotar SECRET en prod.
---


## 3. Rate limiting
- slowapi + Limiter(key_func=get_remote_address)
- /api/auth/register: @limiter.limit('5/hour')
- /api/auth/login: @limiter.limit('10/minute')
- Storage in-memory (default slowapi) — válido para dev; considerar Redis en prod.
- Estado: IMPLEMENTADO.
---


## 4. Inventario endpoints (OpenAPI)
- /api/health (GET, public)
- /api/activities (GET, public)
- /api/children (POST, tutor)
- /api/children/{child_id} (GET, tutor)
- /api/sessions (POST, tutor)
- /api/children/{child_id}/progress (GET, tutor)
- /api/auth/register (POST, public, 5/h)
- /api/auth/login (POST, public, 10/m)
- Validación vía Pydantic (schemas). Autorización vía require_tutor.
- Estado: OK.
---


## 5. Seguridad Rojo (Lua)
- rojo/server/secrets.lua: en .gitignore (sí). Credenciales API (email/password) ahí — no expuesto cliente.
- rojo/server/main.server.lua: Script server-side. HttpService.RequestAsync para login + POST sessions.
- Cache JWT + relogin ante 401 (coincide diseño). Usa pcall(task.cancel, ...) según commits.
- RemoteEvents: conecta handlers, valida tipos (SessionPayload schema en shared/init.lua). Datos recibidos desde cliente: se envían a backend con auth server-side (no se acepta token cliente).
- No se imprimen tokens/secretos en logs (mensajes de error genéricos).
- Añadida y versionada rojo/server/secrets.example.lua (plantilla).
- Estado: OK (secrets.lua protegido y plantilla provista). Riesgo: Baja.
---


## 6. Verificación
- pytest: 14/14 passed (backend/tests).
- Health: /api/health OK en :8000/:8001.
- OpenAPI 3.1.0 OK.
- demo tests: 26/26 passed (vitest).
- Smoke: pendiente endpoints protegidos con/sin token (no ejecutado para no modificar estado).
- demo/.env vs example: ejemplo vacío; prod requiere llenar VITE_SAIYDD_API_URL + VITE_SAIYDD_API_TOKEN.
- Estado: OK (base).
---


## 7. Hallazgos / Recomendaciones (mínimas)
- OK CORS (sin credentials + whitelist dev).
- JWT: mensajes genéricos OK.
- Rate limiting implementado (login/register).
- Rojo: secrets.lua protegido. Plantilla rojo/server/secrets.example.lua añadida.
- No exponer stack traces en prod (ya vía errores estandarizados).
- Token del state temporal puede expirar — usar flujo [8] para refrescar.
- No usar wildcard con allow_credentials=true (no aplicable aquí).
- Riesgo global: Baja. Pendiente completar items 8.2-8.6.
---


## 8. Estado global
- 8.1 (Seguridad): revisión completada sin cambios de código.
- 8.2-8.6: pendientes.
- Paso 0 completado; paso 1 hecho (revisión). Sin commits.


## 8.2 Accesibilidad (demo web + manual) — COMPLETADO
- **Skip-links**: implementados en `demo/index.html` (`#app`) y en `docs/manual-usuario.html` (`#inicio`), con foco visible garantizado.
- **Landmarks y semántica**: `main` con `role="main"`, regiones con `role="region"` y `aria-label` descriptivos.
- **Mascota Orion**: `role="img"`, etiquetas dinámicas según expresión (`aria-label="Mascota Orion: feliz y atento"` etc.) y `aria-pressed` en mute.
- **Selectores y botones**: `radiogroup` accesible con nombres textuales para avatares (Gatito, Perrito, Conejito, Leoncito), emojis decorativos aislados con `aria-hidden="true"`.
- **Notificaciones y estados**: `role="status"` y `aria-live="polite"` en resultados de juego, HUD de bloques y splash; `role="log"` en chatbot; `role="alert"` en PIN inválido.
- **Validación de calidad**: ESLint, Prettier, Vitest (26/26) y Vite build pasando sin advertencias.
- **Estado: COMPLETADO ✅**. Pasar a 8.3.
---


## 8.3 Moderación y consentimiento — COMPLETADO
- **Modelo de Moderación ("Walled Garden")**: Chatbot basado exclusivamente en base de conocimiento curada (`KB`), sin llamadas libres a LLMs. Actividades didácticas estructuradas sin campo de entrada abierta para los menores.
- **Guardrails**: Saneamiento de cadenas (`sanitize.js`), limitación de frecuencia de acciones (`rate-limiter.js`) y endpoints protegidos con rate limiting (`slowapi`).
- **Consentimiento Parental Informado**: Control de acceso previo con PIN en el Panel de Padres. Selector interactivo de consentimiento para almacenar progreso en `dashboard.js` con soporte en `consent.js`.
- **Revocación activa**: Si el tutor desactiva el consentimiento, `juego.js` detiene inmediatamente la persistencia de nuevas sesiones.
- **Derecho al olvido**: Botón de borrado total de perfil, sesiones y avances locales en un solo paso (`clearAllChildData()`).
- **Documentación formal**: Creado `docs/CONSENTIMIENTO_Y_MODERACION.md` detallando las políticas y salvaguardas.
- **Estado: COMPLETADO ✅**. Pasar a 8.4.
---


## 8.4 Privacidad infantil (COPPA/menores)
- Datos mínimos: childId, nombre/avatar, sesiones (score, duración, interacciones). Sin PII sensible evidente.
- Almacenamiento: localStorage demo; backend DB SQLite (sessions/children/tutors).
- Retención: no implementada (pendiente). No tracking (no analytics).
- APIs: no envío a terceros. HTTPS recomendado prod.
- Estado: REVISAR (definir política retención/borrado, no tracking explícito, minimización).
---


## 8.5 Demo web contra backend real
- Config: demo/src/js/config.js lee VITE_SAIYDD_API_URL + VITE_SAIYDD_API_TOKEN. Si URL vacía ? mock.
- api.js (módulo): cuando BACKEND_URL existe usa fetch con Authorization Bearer (si token).
- .env.example vacío; requiere configuración.
- Token puede expirar (state temporal).
- Estado: PREPARADO (config lista). Falta validar con backend real + token válido.
---


## 8.6 Publicación place Roblox
- HttpEnabled guardado en place (SDD).
- Contrato shared, server Script, client bridge OK.
- secrets.lua no versionado.
- Requiere HTTP habilitado, backend accesible desde prod? (localhost solo dev).
- Estado: PENDIENTE (definir dominio/URL backend prod, secretos prod, revisión política).
---


## Resumen item 8.1–8.6 (rapidez)
- 8.1: completado (sin código)
- 8.2: revisión rápida (menores)
- 8.3–8.6: inventario + pendientes documentados
- Sin cambios de código. Editado sin commitear.
- Próximo: decidir qué corregir (mínimo) o pasar a demo real si corresponde.


## 8.3 (detalle rápido)
- Revisando flujo: preaprobados, PIN, backend auth. Sin generación libre ? riesgo moderación bajo.
- Falta política explícita de consentimiento (datos niños). Añadir a pendientes mínimos.
- Sin cambios de código.
---


## 8.4 (detalle rápido)
- Datos mínimos. Sin tracking. Faltar definir retención/borrado (política escrita).
- Recomendación mínima: documentar política en docs (manual/README).
- Sin cambios de código.
---


## 8.5 (detalle rápido)
- Config OK (demo/src/js/config.js + api.js).
- Requiere VITE_SAIYDD_API_URL + VITE_SAIYDD_API_TOKEN válidos. Token puede expirar (usar rojo-manager [8]).
- Smoke opcional: probar con backend corriendo (no ejecutado).
- Sin cambios de código.
---


## 8.6 (detalle rápido)
- HttpService HttpEnabled guardado. secrets no versionado. Server Script.
- Para prod: cambiar apiUrl en secrets.lua a dominio backend (no localhost).
- Sin cambios de código.
---


## Avance roadmap 8
- 8.1 completado ?
- 8.2 documentado ?
- 8.3–8.6 documentados (inventario) ?
- Pendiente: decidir mínimos (secrets.example.lua) vs demo real. Sin commits.


