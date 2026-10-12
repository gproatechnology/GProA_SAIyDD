# SaIyDD â€” Sistema de Aprendizaje Inclusivo

> Prototipo educativo kid-safe para niÃ±os de 4 a 8 aÃ±os, con actividades gamificadas, mascota guÃ­a, interacciÃ³n por voz y panel de progreso para tutores.

Repositorio: [gproatechnology/GProA_SAIyDD](https://github.com/gproatechnology/GProA_SAIyDD.git)

## Estado del proyecto

**Estado actual:** prototipo funcional en fase alfa â€” **consolidado en este repositorio**.

La demo web y la documentaciÃ³n ya estÃ¡n versionadas aquÃ­:

```text
SAIyDD/
â”œâ”€â”€ demo/           # Demo Vite completa (fuentes, assets, build config)
â”œâ”€â”€ docs/           # Manual de usuario interactivo + datos
â””â”€â”€ rojo/           # SincronizaciÃ³n Rojo verificada (shared/server/client)
```

## Arquitectura

```mermaid
flowchart LR
    U[NiÃ±o o tutor] --> W[Demo web con Vite]
    W --> A[app.js - router y orquestaciÃ³n]
    A --> B[bienvenida.js]
    A --> M[menu.js]
    A --> C[chatbot.js]
    A --> J[juego.js]
    A --> G[dashboard.js]
    A --> V[voz.js]
    A --> P[mascota.js / mascota-ui.js]
    B --> D[(data.js)]
    M --> D
    J --> D
    G --> D
    J --> L[(localStorage)]
    G --> L
    A --> API[api.js - mock o backend]
    API -- VITE_SAIYDD_API_URL --> BE[(Backend FastAPI)]
    X[Roblox Studio] -- HttpService --> BE
    X <--> ROJO[Rojo sync]
```

### Flujo principal

```mermaid
sequenceDiagram
    participant N as NiÃ±o/tutor
    participant W as Demo web
    participant A as app.js
    participant M as MÃ³dulos
    participant S as localStorage

    N->>W: Abre la demo
    W->>A: DOMContentLoaded / initApp()
    A->>M: Renderiza bienvenida y menÃº
    M->>S: Guarda perfil y progreso local
    M-->>N: Muestra actividades y retroalimentaciÃ³n
    M-->>N: Reproduce indicaciones con TTS cuando estÃ¡ disponible
```

## MÃ³dulos web

| MÃ³dulo | Responsabilidad |
|---|---|
| `app.js` | Router, vistas y coordinaciÃ³n general |
| `bienvenida.js` | SelecciÃ³n de avatar y recuperaciÃ³n del perfil local |
| `menu.js` | NavegaciÃ³n principal |
| `chatbot.js` | Asistente local con respuestas preaprobadas |
| `juego.js` | Actividades, validaciÃ³n y registro de sesiones |
| `mascota.js` | Expresiones y texto a voz |
| `mascota-ui.js` | Componentes visuales de la mascota |
| `voz.js` | Reconocimiento de voz limitado |
| `dashboard.js` | Panel de progreso para tutores |
| `api.js` | Puerta de acceso mock: datos pÃºblicos + `submitAnswer()` |
| `blocks-world.js` | Actividad interactiva en canvas |
| `sanitize.js` | ValidaciÃ³n y saneamiento de texto |
| `rate-limiter.js` | LÃ­mites locales por tipo de acciÃ³n |

## Estructura del repositorio

```text
SAIyDD/
â”œâ”€â”€ .github/
â”‚   â””â”€â”€ workflows/ci.yml   # CI: demo (npm) + backend (pytest + ruff)
â”œâ”€â”€ LICENSE
â”œâ”€â”€ README.md
â”œâ”€â”€ backend/        # API FastAPI (Python) â€” venv, .env y *.db ignorados
â”‚   â”œâ”€â”€ requirements.txt
â”‚   â”œâ”€â”€ requirements-dev.txt
â”‚   â”œâ”€â”€ .env.example
â”‚   â”œâ”€â”€ app/        # main, auth, errors, repositories, models, schemas, seed
â”‚   â””â”€â”€ tests/      # pytest + httpx (TestClient)
â”œâ”€â”€ demo/
â”‚   â”œâ”€â”€ index.html
â”‚   â”œâ”€â”€ package.json
â”‚   â”œâ”€â”€ package-lock.json
â”‚   â”œâ”€â”€ vite.config.js
â”‚   â””â”€â”€ src/
â”‚       â”œâ”€â”€ assets/
â”‚       â”‚   â””â”€â”€ images/
â”‚       â”œâ”€â”€ css/
â”‚       â”‚   â”œâ”€â”€ variables.css
â”‚       â”‚   â”œâ”€â”€ styles.css
â”‚       â”‚   â””â”€â”€ modules/
â”‚       â”‚       â”œâ”€â”€ screens.css
â”‚       â”‚       â””â”€â”€ blocks-world.css
â”‚       â”œâ”€â”€ js/
â”‚       â”‚   â”œâ”€â”€ main.js
â”‚       â”‚   â”œâ”€â”€ modules/
â”‚       â”‚   â”‚   â”œâ”€â”€ app.js
â”‚       â”‚   â”‚   â”œâ”€â”€ bienvenida.js
â”‚       â”‚   â”‚   â”œâ”€â”€ menu.js
â”‚       â”‚   â”‚   â”œâ”€â”€ chatbot.js
â”‚       â”‚   â”‚   â”œâ”€â”€ dashboard.js
â”‚       â”‚   â”‚   â”œâ”€â”€ juego.js
â”‚       â”‚   â”‚   â”œâ”€â”€ mascota.js
â”‚       â”‚   â”‚   â”œâ”€â”€ mascota-ui.js
â”‚       â”‚   â”‚   â”œâ”€â”€ voz.js
â”‚       â”‚   â”‚   â”œâ”€â”€ blocks-world.js
â”‚       â”‚   â”‚   â””â”€â”€ api.js
â”‚       â”‚   â”œâ”€â”€ utils/
â”‚       â”‚   â”‚   â”œâ”€â”€ sanitize.js
â”‚       â”‚   â”‚   â””â”€â”€ rate-limiter.js
â”‚       â”‚   â””â”€â”€ data/
â”‚       â”‚       â””â”€â”€ data.js
â”œâ”€â”€ docs/
â”‚   â”œâ”€â”€ manual-usuario.html   # Manual interactivo con bÃºsqueda, TOC, tema
â”‚   â”œâ”€â”€ manual.css
â”‚   â””â”€â”€ data.js               # Contenido y renderizado del manual
â”œâ”€â”€ rojo-manager.ps1        # Gestor interactivo: Rojo + backend + flujo completo
â””â”€â”€ rojo/
    â”œâ”€â”€ shared/               # init.lua: contrato compartido (sin secretos)
    â”œâ”€â”€ server/               # main.server.lua (Script: HttpService + JWT) + secrets.lua (ignorado)
    â”œâ”€â”€ client/               # main.lua: bridge cliente (RemoteEvents)
    â”œâ”€â”€ default.project.json  # Ãrbol sincronizado con Studio (incluye Events)
    â””â”€â”€ secrets.example.lua   # Plantilla de credenciales del servicio
```

## EjecuciÃ³n de la demo

Desde la raÃ­z del repo:

```powershell
cd demo
npm install
npm run dev
```

La demo se abre en `http://localhost:5174`.

Para generar una build de producción:

```powershell
npm run build
```

Calidad de cÃ³digo:

```powershell
npm run lint          # ESLint
npm run format        # Prettier (escribe)
npm run format:check  # Prettier (verifica)
npm test              # Vitest (26 pruebas)
```

## Backend (API)

```powershell
cd backend
.venv\Scripts\python.exe -m pip install -r requirements.txt
.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

- Auth de tutores: `POST /api/auth/register` y `POST /api/auth/login` (bcrypt + JWT HS256, token Bearer con `role`).
- Rutas de dominio protegidas con la dependencia `require_tutor` (401 sin/Con token invÃ¡lido, 403 con rol insuficiente); `/api/health` y `/api/activities` son pÃºblicas.
- Rate limiting con slowapi (login 10/min, registro 5/hora) y errores con formato `{"error": {"code", "message"}}`.
- ConfiguraciÃ³n vÃ­a variables de entorno (ver `backend/.env.example`), incluye `JWT_SECRET`.
- La demo se conecta al backend real configurando `VITE_SAIYDD_API_URL` y `VITE_SAIYDD_API_TOKEN` (ver `demo/.env.example`); sin esas variables usa su mock local. `submitAnswer` sigue siendo local: las respuestas son preaprobadas y no existe endpoint de validaciÃ³n.
- Pruebas del backend: `pytest` (14 pruebas con `httpx`/TestClient en `backend/tests/`); lint con `ruff`. Ambos corren en CI (job `backend`).
- La cuenta de servicio de Roblox se registra con `POST /api/auth/register` (o con la opciÃ³n 8 de `rojo-manager.ps1`); sus credenciales viven en `rojo/server/secrets.lua` (ignorado por git).

## Manual de usuario

Abrir `docs/manual-usuario.html` en el navegador (o servir con `npx serve docs`). Incluye:

- Tabla de contenidos navegable
- BÃºsqueda en tiempo real
- Tema claro/oscuro persistente
- Secciones: introducciÃ³n, acceso, mascota, menÃº, juego, chatbot, voz, dashboard, seguridad, alcance, FAQ, soporte

## IntegraciÃ³n con Roblox

```mermaid
flowchart TB
    WEB[Interfaz web SaIyDD] --> API[Servicio backend seguro]
    STUDIO[Roblox Studio] --> LU[Scripts Luau]
    LU --> API
    API --> DB[(Persistencia y progreso)]
    API --> MOD[ModeraciÃ³n y guardrails]
    ROJO[Rojo sync] --> STUDIO
```

### Flujo Studio â†” backend

```mermaid
sequenceDiagram
    participant C as Client (LocalScript)
    participant S as Server (Script)
    participant B as Backend FastAPI
    C->>S: RemoteEvent SAIyDDRecordSession
    S->>B: POST /api/sessions (Bearer JWT)
    B-->>S: 201 + sesiÃ³n registrada
    S-->>C: respuesta por RemoteEvent
```

- `rojo/shared/init.lua`: contrato compartido (endpoints, payloads, RemoteEvents) â€” sin secretos.
- `rojo/server/main.server.lua`: Script del servidor (arranca solo al abrir el place) â€” cliente HTTP (`HttpService:RequestAsync`), login de cuenta de servicio con cache de JWT y relogin ante 401, handlers de los RemoteEvents.
- `rojo/client/main.lua`: bridge cliente (`Client.recordSession` / `Client.healthCheck`, corrutinas con timeout).
- `rojo/server/secrets.lua`: credenciales del servicio (ignorado por git; plantilla en `rojo/secrets.example.lua`).

### Uso con `rojo-manager.ps1`

```powershell
.\rojo-manager.ps1
# [7] Iniciar/detener backend (uvicorn :8000)
# [8] Flujo completo: cuenta de servicio + niÃ±o de prueba + sesiÃ³n + progreso
# [9] Estado integral (puertos, Rojo, backend, Ã¡rbol sincronizado)
```

La opciÃ³n 8 guarda `{apiUrl, token, childId}` en `%TEMP%\saiydd-state.json` para la prueba manual en Studio.

### Prueba en vivo en Studio (manual)

**Requisitos de Studio:**

1. **HTTP habilitado**: Game Settings â†’ Security â†’ **Allow HTTP Requests = ON** (equivalente por cÃ³digo: `HttpService.HttpEnabled = true`; se guarda con el place y persiste en los play tests). Sin esto, `HttpService:RequestAsync` falla con `HTTP 0` y el login contra el backend devuelve `auth_failed`.
2. **Orden de arranque**: backend (opciÃ³n 7 del gestor o uvicorn) â†’ Rojo (opciÃ³n 1) â†’ Studio: Plugins â†’ Rojo â†’ Connect â†’ **Play (F5)**.

Pasos de la prueba:

1. Durante el Play, un LocalScript temporal en StarterPlayerScripts:

   ```lua
   local Client = require(script.Parent:WaitForChild("Client"))
   task.spawn(function()
       local reply = Client.recordSession("child_ID_AQUI", "act_001", 100, 90)
       print("[TEST] recordSession ->", reply.ok)
   end)
   ```

2. Verificar la persistencia compartida:

   ```powershell
   curl.exe -H "Authorization: Bearer $token" http://127.0.0.1:8000/api/children/$childId/progress
   ```

### Preparación actual

| Elemento | Estado |
|---|---|
| Demo web Vite | âœ… Consolidada en `demo/` |
| DocumentaciÃ³n | âœ… Consolidada en `docs/` |
| Repositorio Git remoto | âœ… Conectado y sincronizado |
| Roblox Studio | âœ… Instalado localmente |
| Rojo (extensiÃ³n + CLI) | âœ… Instalado y configurado |
| Proyecto Roblox (`default.project.json`) | âœ… Completado |
| Servicio Roblox (Luau + RemoteEvents) | âœ… Contrato, cliente HTTP, bridge y play test validado |
| Backend + auth de tutores | âœ… SQLModel, bcrypt + JWT, tests y CI |
| Pruebas, linting y accesibilidad | âœ… Completados |
| Accesibilidad y seguridad productiva | ✓ Pendiente |

La sincronizaciÃ³n Rojo, el backend y la integraciÃ³n Studio â†” backend estÃ¡n verificados (`rojo build`, `rojo serve`, flujo API de extremo a extremo), incluyendo la prueba de Play en Studio con registro real de sesiÃ³n en el backend (`Client.recordSession` â†’ RemoteEvent â†’ Script del servidor â†’ `POST /api/sessions` â†’ 201).

## Seguridad y alcance de la demo

- Los datos de perfil y progreso se guardan en `localStorage` del navegador.
- El chat y las actividades usan respuestas preaprobadas; no hay generaciÃ³n libre.
- La voz depende de APIs nativas del navegador y puede no estar disponible en todos los entornos.
- El PIN del panel de padres se configura con la variable de entorno `VITE_SAIYDD_PIN` (ver `demo/.env.example`); el valor por defecto es solo para demo y no debe usarse en producción.
- La demo ya no expone datos en globales (`window.dataMock` eliminado); las respuestas del juego se validan vÃ­a `api.submitAnswer()` y el cliente solo recibe el subconjunto pÃºblico de cada actividad.
- La API del backend protege las rutas de tutor con JWT (registro/login con bcrypt, rate limiting con slowapi, errores estandarizados); el secreto se configura con `JWT_SECRET` (ver `backend/.env.example`).
- La integraciÃ³n Roblox usa una cuenta de servicio de tutor: las credenciales viven en `rojo/server/secrets.lua` (ignorado por git) y el JWT solo existe en ServerScriptService, nunca en el cliente.
- Antes de una publicaciÃ³n real se deben completar validaciones de seguridad, accesibilidad, moderaciÃ³n, consentimiento y privacidad infantil.

## Roadmap

1. âœ… Consolidar en este repositorio la demo, documentaciÃ³n y configuraciÃ³n compartida.
2. âœ… Corregir los hallazgos crÃ­ticos de seguridad (PIN externalizado + fuga de datos cerrada).
3. âœ… AÃ±adir pruebas automatizadas (Vitest), linting (ESLint + Prettier), accesibilidad y CI (GitHub Actions).
4. âœ… Instalar extensiÃ³n Rojo + CLI y crear `default.project.json` + estructura Luau.
5. âœ… Sincronizar Roblox Studio con Rojo (live sync verificado + `rojo build` funcional).
6. âœ… Backend: persistencia SQLModel, auth de tutores (bcrypt + JWT), integraciÃ³n demoâ†”backend, tests y CI.
7. âœ… Roblox Studio â†” backend vÃ­a Rojo (contrato, cliente HTTP con JWT, RemoteEvents, `rojo-manager.ps1` extendido). Play test en Studio validado end-to-end (ver "IntegraciÃ³n con Roblox").
  8. ✓ Preparación para producción COMPLETADO (8.1–8.6: seguridad, accesibilidad, moderación/consentimiento, privacidad infantil, demo real, publicación place).

## Licencia

Ver [LICENSE](LICENSE).













