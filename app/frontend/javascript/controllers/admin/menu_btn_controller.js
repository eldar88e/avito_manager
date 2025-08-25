import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["body"];

  showMenu() {
    this.element.classList.toggle("aside-hide");
    this.bodyTarget.classList.toggle("body-blur");
  }
}
