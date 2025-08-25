import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {}

  async delete(event) {
    let del = confirm("Вы уверены, что хотите удалить это фото?");
    if (del) {
      let item = event.target;
      const id = item.closest("[data-id]").dataset.id;
      const productId =
        event.target.closest("[data-product-id]")?.dataset.productId;

      if (!productId || !id) return;

      const path = `products/${productId}`;
      const url = `/admin/${path}/photos/${id}`;

      const csrfToken = document.querySelector(
        'meta[name="csrf-token"]',
      ).content;

      const response = await fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
      });

      if (response.ok) {
        item.closest("[data-id]").remove();
      } else {
        alert("Ошибка при удалении фото");
      }
    }
  }
}
