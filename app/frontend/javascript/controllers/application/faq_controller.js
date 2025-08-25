import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="faq"
export default class extends Controller {
  static targets = ["answer", "arrow"];

  toggle() {
    this.answerTarget.classList.toggle("open-answer");
    this.arrowTarget.classList.toggle("rotate");
  }
}
