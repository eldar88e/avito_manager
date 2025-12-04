import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  call() {
    this.element.classList.toggle("collapse-bar");
  }
}
