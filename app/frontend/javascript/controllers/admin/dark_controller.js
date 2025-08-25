import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  change() {
    if (this.element.classList.contains("dark")) {
      this.element.classList.remove("dark");
    } else {
      this.element.classList.add("dark");
    }
  }
}
