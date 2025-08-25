import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  show() {
    this.element.classList.toggle("show");
    let menu = document.getElementById("menu");
    if (menu) {
      menu.classList.toggle("show");
      let modal = document.getElementById("modal");
      let button = menu.querySelector("button");
      if (menu.classList.contains("show")) {
        this.menuClose(menu, button);
        if (modal && modal.style.display === "block") {
          modal.style.display = "none";
        }
      }
    }
  }

  menuClose(menu, button) {
    button.addEventListener("click", () => {
      menu.classList.remove("show");
      this.element.classList.remove("show");
    });
  }
}
