function formatDateTime(iso) {
    if (!iso) return "-";
    try {
        const d = new Date(iso);
        return d.toLocaleString("es-ES");
    } catch (e) {
        return iso;
    }
}

function formatSeconds(seconds) {
    if (seconds === null || seconds === undefined) return "-";
    const s = Math.max(0, Math.floor(seconds));
    const m = Math.floor(s / 60);
    const sec = s % 60;
    if (m === 0) return sec + " s";
    return m + "m " + sec + "s";
}

function formatPercent(val) {
    if (val === null || val === undefined) return "-";
    return Math.round(val * 10) / 10 + " %";
}

export { formatDateTime, formatSeconds, formatPercent };
