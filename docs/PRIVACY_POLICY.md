# Política de Privacidad y Protección de Menores (SaIyDD)

Fecha de revisión: 2026-10-13
Alcance: demo web, backend local (FastAPI), integración con Roblox Studio.

## 1. Principios
- Minimización de datos: solo lo estrictamente necesario.
- Sin seguimiento (no ads, no analytics, no pixels).
- Consentimiento parental informado.
- Derecho al olvido (borrado total).
- Datos almacenados localmente para demo; backend usa SQLite para sesiones/control.

## 2. Datos recopilados
- Perfil menor: childId, nombre/avatar.
- Sesiones: score, durationSeconds, interactions (solo métricas educativas).
- Tutor: credenciales para auth JWT (solo backend).

## 3. Almacenamiento
- Demo (navegador): localStorage (perfil, progreso, preferencias).
- Backend: SQLite saiydd.db (tutores, niños, sesiones).

## 4. Retención y borrado
- **Derecho al olvido**: el tutor puede solicitar el borrado total de todos los datos de un menor desde el panel de padres o mediante el endpoint `DELETE /api/children/{childId}` del backend. Al borrar se eliminan el perfil del menor y todas sus sesiones asociadas de forma inmediata e irreversible.
- **Borrado local**: los datos guardados en `localStorage` del navegador (demo web) se borran al usar la opción "Borrado total del menor" en el panel de padres.
- **Borrado en backend**: el endpoint `DELETE /api/children/{childId}` elimina el perfil del menor y todas las sesiones registradas en la base de datos SQLite (`saiydd.db`). Requiere autenticación JWT con rol de tutor.
- **Retención**: no hay caducidad automática implícita. Los datos se conservan hasta que el tutor solicite su borrado explícito. No se establece un período de retención predeterminado; el responsable del tratamiento decide cuándo borrar.
- **Minimización**: solo se almacenan los datos estrictamente necesarios para la experiencia educativa (nombre, avatar, preferencias, puntuación, duración e interacciones de las actividades). No se recopilan datos de ubicación, contacto, ni datos sensibles.

## 5. Seguridad
- HTTPS recomendado en prod.
- JWT, bcrypt, rate limiting, contenido preaprobado.
- Sin envío a terceros.

## 6. Contacto
- Ver README para soporte.

## 7. Enlaces
- Manual: manual-usuario.html
- CONSENTIMIENTO_Y_MODERACION.md
---

