import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        noImageUrl: String
    };

    connect() {
        this.noImageUrlValue = window.location.origin + window.noimage_url;
        this.processImages();
    }

    processImages() {
        const divs = this.element.querySelectorAll('.game-img');
        divs.forEach(div => {
            const img = new Image();
            img.src = div.style.backgroundImage.replace(/^url\(["']?/, '').replace(/["']?\)$/, '');

            img.addEventListener('error', () => this.handleImageError(div));
        });
    }

    handleImageError(div) {
        div.style.backgroundImage = `url(${this.noImageUrlValue})`;
    }
}