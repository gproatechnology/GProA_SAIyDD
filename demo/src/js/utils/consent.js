const CONSENT_KEY = "saiydd_parental_consent";

function getStorage() {
  if (typeof localStorage !== "undefined") {
    return localStorage;
  }
  if (typeof globalThis !== "undefined" && globalThis.localStorage) {
    return globalThis.localStorage;
  }
  return null;
}

/**
 * Obtiene el estado actual del consentimiento parental.
 * Por defecto en la demo, si no se ha configurado, retorna no otorgado.
 */
export function getConsentStatus() {
  try {
    const storage = getStorage();
    if (!storage) {
      return { granted: false, timestamp: null, guardianConfirmed: false };
    }
    const raw = storage.getItem(CONSENT_KEY);
    if (!raw) {
      return { granted: false, timestamp: null, guardianConfirmed: false };
    }
    const parsed = JSON.parse(raw);
    return {
      granted: Boolean(parsed.granted),
      timestamp: parsed.timestamp || null,
      guardianConfirmed: Boolean(parsed.guardianConfirmed),
    };
  } catch {
    return { granted: false, timestamp: null, guardianConfirmed: false };
  }
}

/**
 * Guarda la decisión del tutor respecto al consentimiento de telemetría y sesiones.
 */
export function setConsent(granted) {
  const status = {
    granted: Boolean(granted),
    timestamp: new Date().toISOString(),
    guardianConfirmed: Boolean(granted),
  };
  try {
    const storage = getStorage();
    if (storage) {
      storage.setItem(CONSENT_KEY, JSON.stringify(status));
    }
  } catch {
    // ignorar posibles errores de cuota en almacenamiento local
  }
  return status;
}

/**
 * Comprueba de forma rápida si el consentimiento está activo.
 */
export function isConsentGranted() {
  return getConsentStatus().granted;
}

/**
 * Elimina todos los datos locales relacionados con el menor (derecho al olvido).
 * Remueve perfil, sesiones, bloques y estadísticas.
 */
export function clearAllChildData({ preserveConsent = true } = {}) {
  try {
    const storage = getStorage();
    if (!storage) return false;

    const keysToRemove = [];
    const len = storage.length || 0;
    for (let i = 0; i < len; i++) {
      const key = storage.key(i);
      if (key && (key.startsWith("saiydd_") || key.startsWith("saiydd-"))) {
        if (preserveConsent && key === CONSENT_KEY) {
          continue;
        }
        keysToRemove.push(key);
      }
    }
    keysToRemove.forEach((k) => storage.removeItem(k));
    return true;
  } catch {
    return false;
  }
}

/**
 * Depura sesiones cuya antigüedad supere maxDays (política de retención COPPA).
 * Retorna la cantidad de sesiones depuradas.
 */
export function pruneExpiredSessions(maxDays = 90) {
  try {
    const storage = getStorage();
    if (!storage) return 0;
    const cutoff = Date.now() - maxDays * 24 * 60 * 60 * 1000;
    let prunedCount = 0;

    const len = storage.length || 0;
    for (let i = 0; i < len; i++) {
      const key = storage.key(i);
      if (key && key.startsWith("saiydd_sessions_")) {
        const raw = storage.getItem(key);
        if (!raw) continue;
        try {
          const sessions = JSON.parse(raw);
          if (Array.isArray(sessions)) {
            const fresh = sessions.filter((s) => {
              const sessionTime = s.finishedAt || s.startedAt;
              if (!sessionTime) return true;
              const t = new Date(sessionTime).getTime();
              return isNaN(t) || t >= cutoff;
            });
            prunedCount += sessions.length - fresh.length;
            storage.setItem(key, JSON.stringify(fresh));
          }
        } catch {
          // ignorar errores de formato
        }
      }
    }
    return prunedCount;
  } catch {
    return 0;
  }
}
