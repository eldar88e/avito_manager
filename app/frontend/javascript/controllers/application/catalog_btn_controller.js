import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.catalogMenu = document.getElementById("catalogMenu");
  }

  toggle() {
    this.catalogMenu.classList.toggle("open");
  }
}
