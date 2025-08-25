import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["notice"];

  connect() {
    const modal = this.noticeTarget;
    if (!modal) return;

    if (localStorage.getItem("cookiesAccepted") === "true") {
      modal.style.display = "none";
      return;
    }

    if (sessionStorage.getItem("cookiesClosed") === "true") {
      modal.style.display = "none";
      return;
    } else {
      modal.style.display = "block";
    }

    modal.querySelector(".yes-cookie").addEventListener("click", () => {
      localStorage.setItem("cookiesAccepted", "true");
      modal.style.display = "none";
    });

    modal.querySelector(".no-cookie").addEventListener("click", () => {
      window.location.href = "https://yandex.ru";
    });

    modal
      .querySelector(".cookie-policy-button")
      .addEventListener("click", () => {
        sessionStorage.setItem("cookiesClosed", "true");
        modal.style.display = "none";
      });
  }
}
