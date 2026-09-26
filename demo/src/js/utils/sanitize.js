export function escapeHtml(str) {
  if (typeof str !== 'string') return '';
  return str.replace(/[&<>"']/g, (m) => ({ '&': '&', '<': '<', '>': '>', '"': '"', "'": ''' }[m] || m));
}

export function clampText(text, max = 200) {
  if (typeof text !== 'string') return '';
  const t = text.trim();
  return t.length > max ? t.slice(0, max - 3) + '...' : t;
}

export function isSafeText(text) {
  if (typeof text !== 'string') return false;
  const t = text.trim();
  if (!t) return false;
  if (t.length > 500) return false;
  return true;
}