const voz = {
  recognition: null,
  listening: false,

  init() {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) return false;
    this.recognition = new SR();
    this.recognition.lang = 'es-MX';
    this.recognition.interimResults = false;
    this.recognition.maxAlternatives = 1;
    return true;
  },

  start(onResult, onEnd) {
    if (!this.recognition || this.listening) return;
    this.listening = true;
    this.recognition.onresult = (e) => onResult?.(e.results[0][0].transcript.trim());
    this.recognition.onend = () => { this.listening = false; onEnd?.(); };
    try { this.recognition.start(); } catch { this.listening = false; }
  },

  stop() {
    if (!this.recognition) return;
    try { this.recognition.stop(); } catch { this.listening = false; }
  },
};

export default voz;