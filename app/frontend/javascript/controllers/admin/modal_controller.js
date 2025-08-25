import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (event) => {
      if (event.target === this.element) {
        this.close();
      }
    });
  }

  close() {
    this.element.classList.add("hidden");
    this.element.setAttribute("aria-hidden", "true");
    document.getElementById("body").classList.remove("blur-xs");
    document.getElementById("header").classList.remove("blur-xs");
  }
}
