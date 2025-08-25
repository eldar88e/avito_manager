import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.mobileCatalogMenu = document.getElementById("mobile-menu");
    this.mobileCatalogOverlay = document.querySelector(
      ".mobile-catalog-overlay",
    );
    this.submenuItems = document.querySelectorAll(
      ".mobile-catalog-menu__item.has-submenu",
    );
    if (
      window.location.pathname.includes("products") ||
      window.location.pathname === "/"
    ) {
      document.getElementById("mobile-menu-btn").classList.add("active");
    }
  }

  toggle() {
    this.mobileCatalogMenu.classList.add("active");
    this.mobileCatalogOverlay.classList.add("active");
    document.body.style.overflow = "hidden";
    if (!this.element.classList.contains("active")) {
      this.element.classList.add("active");
    }
  }

  close() {
    this.mobileCatalogMenu.classList.remove("active");
    this.mobileCatalogOverlay.classList.remove("active");
    document.body.style.overflow = "auto";
  }

  open(event) {
    event.preventDefault();
    event.stopPropagation();

    const item = event.target.closest(".mobile-catalog-menu__item");
    if (item) item.classList.toggle("open");
  }
}
