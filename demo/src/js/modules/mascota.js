const mascota = {
  synth: window.speechSynthesis,
  voice: null,
  muted: false,
  expression: 'neutral',

  EXPRESSIONS: {
    neutral: '😊',
    happy: '🥳',
    encourage: '🤩',
    surprise: '😲',
  },

  init() {
    if (!this.synth) return;
    const setVoice = () => {
      try {
        const list = this.synth.getVoices?.() || [];
        this.voice = list.find(x => x.lang?.startsWith('es')) || null;
      } catch {
        this.voice = null;
      }
    };
    setVoice();
    this.synth.addEventListener?.('voiceschanged', setVoice);
  },

  setExpression(name) {
    if (this.EXPRESSIONS[name]) this.expression = name;
  },

  toggleMute() {
    this.muted = !this.muted;
    if (this.muted) this.stop();
    return this.muted;
  },

  say(text, opts = {}) {
    if (!this.synth || this.muted) return;
    const u = new SpeechSynthesisUtterance(text);
    if (this.voice) u.voice = this.voice;
    u.pitch = opts.pitch ?? 1.3;
    u.rate = opts.rate ?? 0.9;
    this.synth.speak(u);
  },

  stop() {
    if (this.synth) this.synth.cancel();
  },
};

export default mascota;