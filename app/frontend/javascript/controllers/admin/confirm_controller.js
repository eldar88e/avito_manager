import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  call(e) {
    let message = this.element.getAttribute("data-confirm");
    if (!confirm(message)) {
      e.preventDefault();
    }
  }
}
