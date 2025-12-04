import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "panel"];
  static values = {
    activeTabClasses: String,
    inactiveTabClasses: String,
  };

  connect() {
    // Активируем первый таб при инициализации
    if (this.tabTargets.length > 0) this.activate(0);
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget);
    if (index >= 0) this.activate(index);
  }

  activate(index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index;
      tab.setAttribute("aria-selected", active ? "true" : "false");

      // классы активного/неактивного
      this._setClasses(tab, active);

      // показать/скрыть панель
      const panel = this.panelTargets[i];
      if (panel) panel.classList.toggle("hidden", !active);
    });
  }

  _setClasses(el, active) {
    const activeClasses = (this.activeTabClassesValue || "")
      .split(" ")
      .filter(Boolean);
    const inactiveClasses = (this.inactiveTabClassesValue || "")
      .split(" ")
      .filter(Boolean);
    // базовый вид вкладки
    const base = [
      "px-3",
      "py-2",
      "text-sm",
      "font-medium",
      "-mb-px",
      "border-b-2",
      "focus:outline-none",
    ];
    el.className = base.join(" ");
    el.classList.add(
      ...(active ? activeClasses : ["border-transparent", ...inactiveClasses]),
    );
  }
}
