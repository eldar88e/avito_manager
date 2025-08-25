import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.agreement = document.getElementById("agreement");
    this.modalBlock = document.getElementById("modal-block");
  }

  open(event) {
    event.preventDefault();
    this.modalBlock.innerHTML = this.agreement.innerHTML;
    document.body.style.overflow = "hidden";
    openModal();
  }
}
