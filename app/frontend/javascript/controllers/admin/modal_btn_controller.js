import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  open() {
    const modal = document.getElementById("modal");
    setTimeout(() => {
      modal.classList.remove("hidden");
      modal.removeAttribute("aria-hidden");
      document.getElementById("body").classList.add("blur-xs");
      document.getElementById("header").classList.add("blur-xs");
    }, 100);
  }
}
