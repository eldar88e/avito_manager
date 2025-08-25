import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "template"];

  add() {
    const clone = this.templateTarget.content.cloneNode(true);
    this.containerTarget.appendChild(clone);
  }

  close(event) {
    event.target.parentElement.parentElement.remove();
  }
}
