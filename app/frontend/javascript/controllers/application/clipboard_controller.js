import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["text"]

    copy() {
        const text = this.textTarget.innerText;
        navigator.clipboard.writeText(text);
    }
}
