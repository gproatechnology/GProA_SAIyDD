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
- Datos pueden borrarse desde Panel de padres → "Borrado total del menor".
- Al borrar se elimina localStorage y puede afectar registros backend según operación.
- Retención mínima; sin caducidad automática implícita (pendiente definir política formal).

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

