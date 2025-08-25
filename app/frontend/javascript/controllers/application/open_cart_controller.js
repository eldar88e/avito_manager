import { Controller } from "@hotwired/stimulus";
//import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  openCart() {
    setTimeout(() => {
      // Turbo.visit("/carts");
      window.location.href = "/carts";
    }, 100);
  }
}
