import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    text: String,
    timeout: { type: Number, default: 5000 },
  };

  connect() {
    this.startTimer();
  }

  startTimer() {
    const selector = `[data-notices-text-value="${this.textValue}"]`;
    const notices = document.querySelectorAll(selector);
    const lastElement = notices[notices.length - 1];

    notices.forEach((element) => {
      if (element !== this.element && element !== lastElement) {
        this.fadeOutAndRemove(element, 50);
      }
    });

    this.timer = setInterval(() => {
      this.fadeOutAndRemove(this.element);
    }, this.timeoutValue);
  }

  fadeOutAndRemove(element, time = 1000) {
    element.classList.add("fade-out");
    setTimeout(() => {
      element.remove();
    }, time);
  }

  close() {
    clearInterval(this.timer);
    this.fadeOutAndRemove(this.element);
  }
}
