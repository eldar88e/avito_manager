import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    words: { type: Array, default: ["Витамин C", "Витамин D"] },
  };

  connect() {
    this.start();
  }

  start() {
    this.currentWordIndex = 0;
    this.currentCharIndex = 0;
    this.typing = true;
    this.cursorVisible = true;
    this.stopped = false;
    this.startTyping();
    this.toggleCursor();
  }

  stop() {
    this.stopped = true;
    clearTimeout(this.typingTimeout);
    clearTimeout(this.cursorTimeout);
    this.element.placeholder = "";
  }

  startTyping() {
    if (this.stopped) return;

    const word = this.wordsValue[this.currentWordIndex].substring(0, 33);

    if (this.typing) {
      if (this.currentCharIndex <= word.length) {
        this.updateText(word.substring(0, this.currentCharIndex));
        this.currentCharIndex++;
        this.typingTimeout = setTimeout(() => this.startTyping(), 200);
      } else {
        this.typing = false;
        this.typingTimeout = setTimeout(() => this.startTyping(), 10);
      }
    } else {
      if (this.currentCharIndex >= 0) {
        this.updateText(word.substring(0, this.currentCharIndex));
        this.currentCharIndex--;
        this.typingTimeout = setTimeout(() => this.startTyping(), 150);
      } else {
        this.typing = true;
        this.currentWordIndex =
          (this.currentWordIndex + 1) % this.wordsValue.length;
        this.typingTimeout = setTimeout(() => this.startTyping(), 10);
      }
    }
  }

  updateText(text) {
    this.element.placeholder = this.cursorVisible ? `${text}|` : text;
  }

  toggleCursor() {
    if (this.stopped) return;

    this.cursorVisible = !this.cursorVisible;
    const currentText = this.element.placeholder.replace(/\|$/, "");
    this.updateText(currentText);
    this.cursorTimeout = setTimeout(() => this.toggleCursor(), 300);
  }
}
