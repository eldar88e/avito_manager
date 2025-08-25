import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  toggle(event) {
    event.stopPropagation();
    this.closeOtherMenus();
    const isHidden = this.menuTarget.classList.toggle("hidden");
    if (!isHidden) {
      document.addEventListener("click", this.handleDocumentClick.bind(this));
    }
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden");
      document.removeEventListener(
        "click",
        this.handleDocumentClick.bind(this),
      );
    }
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden");
    }
  }

  update(event) {
    event.preventDefault(); // Отменить переход по ссылке
    const selectedText = event.target.textContent.trim(); // Текст выбранного пункта
    this.element.querySelector("button").textContent = selectedText; // Обновляем текст кнопки
    this.menuTarget.classList.add("hidden"); // Скрыть меню
  }

  closeOtherMenus() {
    document
      .querySelectorAll("[data-controller='dropdown']")
      .forEach((dropdown) => {
        if (dropdown !== this.element) {
          const menu = dropdown.querySelector("[data-dropdown-target='menu']");
          if (menu && !menu.classList.contains("hidden")) {
            menu.classList.add("hidden");
          }
        }
      });
  }
}
