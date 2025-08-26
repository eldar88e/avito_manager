import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    clearForm(event) {
        if (event.detail.success) {
            this.element.reset();
        }
    }
}
