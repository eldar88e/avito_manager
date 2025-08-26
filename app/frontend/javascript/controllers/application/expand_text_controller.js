import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["message", "button"];

    connect() {
        this.checkTextLength();
        window.addEventListener('resize', this.checkTextLength.bind(this));
    }

    disconnect() {
        window.removeEventListener('resize', this.checkTextLength.bind(this));
    }

    call() {
        this.element.classList.toggle('open');
    }

    checkTextLength() {
        const textLength = this.messageTarget.textContent.length;
        const screenWidth = window.innerWidth;

        if (textLength <= 200 && screenWidth > 768) {
            this.buttonTarget.style.display = 'none';
        } else {
            this.buttonTarget.style.display = '';
        }
    }
}
