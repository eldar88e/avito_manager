import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.modal = document.getElementById("modal");
  }

  open() {
    this.modal.classList.remove("hidden");
  }

  close() {
    this.modal.classList.add("hidden");
  }

  closeModal(e) {
    if (e.target === this.element) {
      this.modal.classList.add("hidden");
    }
  }
}
