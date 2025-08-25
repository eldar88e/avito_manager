import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { id: { type: Number } };

  connect() {}

  async delete(event) {
    let del = confirm("Вы уверены, что хотите удалить это вложение?");
    if (del) {
      const item = event.target.closest(".edit-image-preview");
      const url = `/admin/attachments/${this.idValue}`;

      try {
        await fetch(url, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
              .content,
            Accept: "application/json",
          },
        });
        item.remove();
      } catch (error) {
        console.error("Error deleting attachment:", error);
      }
    }
  }
}
