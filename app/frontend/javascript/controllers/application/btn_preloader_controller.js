import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    call(e) {
        this.element.insertAdjacentHTML('afterbegin', '<div id="loader" class="loader"></div>');

        setTimeout(() => {
            this.element.querySelector('#loader').remove();
        }, 1000);
    }
}
