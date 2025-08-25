import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["stars", "hiddenInput"];

  select(event) {
    const selectedRating = parseInt(event.currentTarget.dataset.value, 10);
    this.hiddenInputTarget.value = selectedRating;
    this.updateStars(selectedRating);
  }

  updateStars(rating) {
    this.starsTargets.forEach((star, index) => {
      if (index < rating) {
        star.classList.add("filled-star");
      } else {
        star.classList.remove("filled-star");
      }
    });
  }
}
