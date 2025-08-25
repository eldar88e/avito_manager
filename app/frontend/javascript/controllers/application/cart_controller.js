import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["delivery", "itemQuantity"];

  connect() {
    this.toggleDeliveryVisibility();
  }

  toggleDeliveryVisibility() {
    const shouldHideDelivery =
      this.itemQuantityTargets.length > 1 ||
      this.getQuantityForSingleItem() > 1;

    if (shouldHideDelivery) {
      this.deliveryTarget.classList.add("hidden");
    } else {
      this.deliveryTarget.classList.remove("hidden");
    }
  }

  getQuantityForSingleItem() {
    const firstItemQuantityElement =
      this.itemQuantityTargets[0].querySelector(".num");
    return firstItemQuantityElement
      ? parseInt(firstItemQuantityElement.textContent)
      : 0;
  }
}
