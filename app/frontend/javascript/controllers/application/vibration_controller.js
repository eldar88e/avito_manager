import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  makeVibration() {
    let type = "medium";
    if (window.Telegram?.WebApp?.HapticFeedback) {
      Telegram.WebApp.HapticFeedback.impactOccurred(type);
    }
  }
}
